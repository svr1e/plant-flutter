import tensorflow as tf

print("Loading best_model...")
m1 = tf.keras.models.load_model('best_model.keras')
print("Saving clean best_model.keras...")
tf.keras.models.save_model(m1, 'best_model_clean.keras', include_optimizer=False)

print("Loading final_soil_model...")
m2 = tf.keras.models.load_model('final_soil_model.keras')
print("Saving clean final_soil_model.keras...")
tf.keras.models.save_model(m2, 'final_soil_model_clean.keras', include_optimizer=False)
print("Done!")
