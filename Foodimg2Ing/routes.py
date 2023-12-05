from flask import render_template, url_for, flash, redirect, request
from CeleryWorker.celery_worker import celery_app, add_event_task, get_top_8_events
from Foodimg2Ing import app
from Foodimg2Ing.output import output
import logging
import json
import os
import uuid

app.logger.setLevel(logging.DEBUG)
logger = logging.getLogger(__name__)


@app.route("/", methods=["GET"])
def home():
    return render_template("home.html")


@app.route("/about", methods=["GET"])
def about():
    return render_template("about.html")


@app.route("/", methods=["POST", "GET"])
def predict():
    imagefile = request.files["imagefile"]
    image_path = os.path.join(app.root_path, "static", "demo_imgs", imagefile.filename)
    imagefile.save(image_path)
    img = "/images/demo_imgs/" + imagefile.filename
    title, ingredients, recipe = output(image_path)
    add_event_task.delay(
        str(uuid.uuid4()),
        title[0],
        recipe[0],
        ingredients[0],
    )
    return render_template(
        "predict.html", title=title, ingredients=ingredients, recipe=recipe, img=img
    )


@app.route("/<samplefoodname>")
def predictsample(samplefoodname):
    imagefile = os.path.join(app.root_path, "static", "images", f"{samplefoodname}.jpg")
    img = "/images/" + str(samplefoodname) + ".jpg"
    title, ingredients, recipe = output(imagefile)
    return render_template(
        "predict.html", title=title, ingredients=ingredients, recipe=recipe, img=img
    )


@app.route("/latest")
def latest():
    events = get_top_8_events()

    html = '<div class="container mt-4">'
    if len(events) > 0:
        html += '<h3>Latest Recipes</h3>'

    for event in events:
        title = event[b"title"].decode("utf-8")
        ingredients = json.loads(event[b"ingredients"].decode("utf-8"))
        recipe = json.loads(event[b"recipe"].decode("utf-8"))

        ingredients_list = ", ".join(
            ingredient for ingredient in ingredients.values()
        )

        html += '<div class="card mb-4">'
        html += '<div class="card-header">'
        html += f'<h5 class="card-title">{title}</h5>'
        html += "</div>"
        html += '<div class="card-body">'

        html += (
            '<p class="card-text">Ingredients:'
            + ingredients_list
            + "</p>"
        )

        html += '<h5 class="card-text mb-2">Recipe</h5>'
        html += "<ol style='padding-left: 5px'>"
        for step in recipe.values():
            html += f"<li>{step}</li>"
        html += "</ol>"

        html += "</div>"
        html += "</div>"

    html += "</div>"
    return html
