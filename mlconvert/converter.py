import os
import zipfile
import urllib.request
import coremltools as ct
import onnx

# Step 1: Download and extract the ONNX model
url = "https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_l.zip"
zip_path = "buffalo_l.zip"
model_dir = "buffalo_l"
onnx_path = os.path.join(model_dir, "w600k_r50.onnx")

if not os.path.exists(model_dir):
    print("📥 Downloading ONNX model...")
    urllib.request.urlretrieve(url, zip_path)

    print("📦 Unzipping...")
    with zipfile.ZipFile(zip_path, "r") as zip_ref:
        zip_ref.extractall(model_dir)

    os.remove(zip_path)

# Step 2: Load and verify the ONNX model
onnx_model = onnx.load(onnx_path)
onnx.checker.check_model(onnx_model)
print("✅ ONNX model is valid")

# Step 3: Convert to CoreML
print("🔁 Converting to CoreML...")
mlmodel = ct.converters.onnx.convert(model=onnx_path)


# Step 4: Save the model
output_model_path = "BuffaloL.mlmodel"
mlmodel.save(output_model_path)
print(f"✅ Saved CoreML model to {output_model_path}")