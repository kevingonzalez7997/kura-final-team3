from celery import Celery
import json
import redis
import time

celery_app = Celery("app")
celery_app.conf.update(
    broker_url="redis://redis:6379/0",
    result_backend="redis://redis:6379/0",
    task_serializer="json",
    accept_content=["json"],
    timezone="UTC",
    enable_utc=True,
)

redis_client = redis.Redis(host="redis", port=6379, db=0)


@celery_app.task(name="CeleryApp.celery_worker.add_event_task")
def add_event_task(event_id, title, recipe, ingredients):
    timestamp = int(time.time())
    recipe_dict = {i: word for i, word in enumerate(recipe, 1)}
    recipe_json = json.dumps(recipe_dict)
    ingredients_dict = {i: word for i, word in enumerate(ingredients, 1)}
    ingredients_json = json.dumps(ingredients_dict)

    redis_client.hset(
        f"event:{event_id}",
        mapping={
            "title": title,
            "recipe": recipe_json,
            "ingredients": ingredients_json,
        },
    )
    redis_client.zadd("top8:datetime", {event_id: timestamp})
    trim_to_top_8.delay()


@celery_app.task(name="CeleryApp.celery_worker.trim_to_top_8")
def trim_to_top_8():
    to_remove = redis_client.zrange("top8:datetime", 0, -9)
    for event_id in to_remove:
        redis_client.delete(f"event:{event_id.decode()}")
    redis_client.zremrangebyrank("top8:datetime", 0, -9)


def get_top_8_events():
    top_event_ids = redis_client.zrevrange("top8:datetime", 0, 7)
    events = []
    for event_id in top_event_ids:
        event_details = redis_client.hgetall(f"event:{event_id.decode()}")
        events.append(event_details)
    return events


if __name__ == "__main__":
    celery_app.worker_main()
