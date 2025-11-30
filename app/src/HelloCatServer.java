// Простое Java-приложение на встроенном HTTP-сервере JDK.
// - Отдаёт страницу с котиком по /
// - Health-check по /health

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class HelloCatServer {

    public static void main(String[] args) throws IOException {
        //Читаем порт из env
        String portEnv = System.getenv("PORT");
        if (portEnv == null) {
            throw new IllegalStateException("Environment variable PORT is not set");
        }

        int port;
        try {
            port = Integer.parseInt(portEnv);
        } catch (NumberFormatException e) {
            throw new IllegalStateException("Environment variable PORT must be an integer: " + portEnv);
        }
        //Создаем встроенный HTTP серевр, слушающий-принимающий http  запросы
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/", new IndexHandler()); // Маршрут для странички с мольбами о трудосутсройстве
        server.createContext("/cat", new CatHandler()); // Маршрут возвращающий картинку кота
        server.createContext("/health", new HealthHandler()); // Маршрут для отслеживания работы сервиса
        server.createContext("/hello", new HelloHandler()); // Возвращает hello world

        //Используем дефолтный пул потоков
        server.setExecutor(null);

        System.out.println("Cat server started on port " + port);
        server.start();
    }

    // HTML страница с котиком
    static class IndexHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String html = """
                    <html>
                      <head><title>Hello Cat</title></head>
                      <body>
                        <h1>Hello Cat!</h1>
                        <p>Вот котик из Java-приложения:</p>
                        <img src="/cat" alt="cat" style="max-width:400px;">
                      </body>
                    </html>
                    """;
            byte[] bytes = html.getBytes();
            exchange.getResponseHeaders().add("Content-Type", "text/html; charset=utf-8");
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        }
    }

    // Эндпоинт: Hello World
    static class HelloHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String msg = "Hello World";
            exchange.sendResponseHeaders(200, msg.length());
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(msg.getBytes());
            }
        }
    }

    // Картинка cat.jpg
    static class CatHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            File catFile = new File("static/cat.jpg");

            if (!catFile.exists()) {
                String err = "Cat image not found";
                exchange.sendResponseHeaders(500, err.length());
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(err.getBytes());
                }
                return;
            }

            exchange.getResponseHeaders().add("Content-Type", "image/jpeg");
            exchange.sendResponseHeaders(200, catFile.length());

            try (FileInputStream fis = new FileInputStream(catFile);
                 OutputStream os = exchange.getResponseBody()) {
                byte[] buffer = new byte[8192];
                int read;
                while ((read = fis.read(buffer)) != -1) {
                    os.write(buffer, 0, read);
                }
            }
        }
    }

    // Health-check
    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = "OK";
            exchange.sendResponseHeaders(200, response.length());
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(response.getBytes());
            }
        }
    }
}
