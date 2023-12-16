import sys
import os

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3' 
sys.stdout = open(os.devnull, "w")  # silence stdout

import tensorflow as tf
from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.efficientnet import EfficientNetB7, preprocess_input, decode_predictions
import numpy as np
import json  # Import the json module


def load_efficientnet_model():
    model = EfficientNetB7(weights='imagenet')
    return model

def preprocess_image(image_path):
    img = image.load_img(image_path, target_size=(600, 600))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array = preprocess_input(img_array)
    return img_array

def identify_content(image_path):
    model = load_efficientnet_model()
    img_array = preprocess_image(image_path)

    predictions = model.predict(img_array)
    decoded_predictions = decode_predictions(predictions, top=3)
    
    # Get the top predictions
    top_predictions_r = [{'label': label, 'probability': prob * 100} for (_, label, prob) in decoded_predictions[0]]
    return top_predictions_r

if __name__ == "__main__":
    # Modify the image path based on the parameter received from Flutter
    image_path_from_flutter = sys.argv[1]
    top_predictions = identify_content(image_path_from_flutter)

    sys.stdout = sys.__stdout__  # unsilence stderr

    # Print the top predictions in JSON format
    print(json.dumps(top_predictions))
