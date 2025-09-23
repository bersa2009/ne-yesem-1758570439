#!/usr/bin/env python3
"""
Simple script to generate a TensorFlow Lite model for recipe matching.
This creates a basic neural network for ingredient-recipe matching.
"""

import json
import numpy as np
import tensorflow as tf
from tensorflow import keras
import os

def load_data():
    """Load training data and create feature vectors."""
    # Load ingredients and recipes
    with open('assets/ingredients.json', 'r', encoding='utf-8') as f:
        ingredients = json.load(f)
    
    with open('assets/recipes.json', 'r', encoding='utf-8') as f:
        recipes = json.load(f)
    
    with open('assets/data/ai_training_data.json', 'r', encoding='utf-8') as f:
        training_data = json.load(f)
    
    # Create ingredient to index mapping
    ingredient_ids = [ing['id'] for ing in ingredients]
    ingredient_to_idx = {ing_id: idx for idx, ing_id in enumerate(ingredient_ids)}
    
    # Create recipe to index mapping
    recipe_ids = [recipe['id'] for recipe in recipes]
    recipe_to_idx = {recipe_id: idx for idx, recipe_id in enumerate(recipe_ids)}
    
    return ingredients, recipes, training_data, ingredient_to_idx, recipe_to_idx

def create_feature_vectors(training_data, ingredient_to_idx, recipe_to_idx, num_ingredients, num_recipes):
    """Create feature vectors from training data."""
    X = []  # Features: ingredient presence + recipe features
    y = []  # Target: normalized score
    
    for sample in training_data['training_samples']:
        # Create ingredient presence vector
        ingredient_vector = np.zeros(num_ingredients)
        for ing_id in sample['user_ingredients']:
            if ing_id in ingredient_to_idx:
                ingredient_vector[ingredient_to_idx[ing_id]] = 1.0
        
        # Create recipe one-hot vector
        recipe_vector = np.zeros(num_recipes)
        if sample['recipe_id'] in recipe_to_idx:
            recipe_vector[recipe_to_idx[sample['recipe_id']]] = 1.0
        
        # Combine features
        feature_vector = np.concatenate([ingredient_vector, recipe_vector])
        X.append(feature_vector)
        
        # Normalize score to 0-1 range
        normalized_score = sample['expected_score'] / 100.0
        y.append(normalized_score)
    
    return np.array(X), np.array(y)

def create_model(input_size):
    """Create a simple neural network model."""
    model = keras.Sequential([
        keras.layers.Dense(64, activation='relu', input_shape=(input_size,)),
        keras.layers.Dropout(0.3),
        keras.layers.Dense(32, activation='relu'),
        keras.layers.Dropout(0.2),
        keras.layers.Dense(16, activation='relu'),
        keras.layers.Dense(1, activation='sigmoid')  # Output score 0-1
    ])
    
    model.compile(
        optimizer='adam',
        loss='mse',
        metrics=['mae']
    )
    
    return model

def main():
    print("Loading data...")
    ingredients, recipes, training_data, ingredient_to_idx, recipe_to_idx = load_data()
    
    num_ingredients = len(ingredients)
    num_recipes = len(recipes)
    
    print(f"Found {num_ingredients} ingredients and {num_recipes} recipes")
    
    # Create feature vectors
    X, y = create_feature_vectors(training_data, ingredient_to_idx, recipe_to_idx, num_ingredients, num_recipes)
    
    print(f"Created {len(X)} training samples with {X.shape[1]} features")
    
    # Create and train model
    model = create_model(X.shape[1])
    
    print("Training model...")
    # Train with data augmentation by duplicating samples with slight noise
    X_augmented = []
    y_augmented = []
    
    for _ in range(10):  # Create 10x more training data
        noise = np.random.normal(0, 0.01, X.shape)
        X_augmented.append(X + noise)
        y_augmented.append(y)
    
    X_train = np.vstack(X_augmented)
    y_train = np.concatenate(y_augmented)
    
    model.fit(X_train, y_train, epochs=100, batch_size=8, verbose=1, validation_split=0.2)
    
    # Convert to TensorFlow Lite
    print("Converting to TensorFlow Lite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save the model
    os.makedirs('assets/models', exist_ok=True)
    with open('assets/models/recipe_matcher.tflite', 'wb') as f:
        f.write(tflite_model)
    
    # Save metadata
    metadata = {
        'ingredient_to_idx': ingredient_to_idx,
        'recipe_to_idx': recipe_to_idx,
        'num_ingredients': num_ingredients,
        'num_recipes': num_recipes,
        'feature_size': X.shape[1],
        'version': '1.0'
    }
    
    with open('assets/models/model_metadata.json', 'w', encoding='utf-8') as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)
    
    print("Model saved successfully!")
    print(f"Model size: {len(tflite_model)} bytes")

if __name__ == '__main__':
    main()