from fastapi import FastAPI

app = FastAPI(title="Simple FastAPI App", version="1.0.0")


@app.get("/")
def read_root():
    return {"message": "Hello World!"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}
