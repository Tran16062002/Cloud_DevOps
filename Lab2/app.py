from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello from Docker container!"

if __name__ == '__main__':
    # Для демонстрации запускаем на всех интерфейсах
    app.run(host='0.0.0.0', port=5000)
