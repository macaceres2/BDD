<?php
session_start();

// Si el usuario ya está logueado, redirigirlo a la página principal
if (isset($_SESSION['loggedin']) && $_SESSION['loggedin'] === true) {
    header("Location: main.php");
    exit();
}

require_once 'utils.php';

// Manejo del envío del formulario de login
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    
    // 1. Obtener datos del formulario (usando los 'name' correctos del HTML)
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';

    // 2. Validación simple
    if (empty($username) || empty($password)) {
        $_SESSION['error_message'] = "Por favor, ingresa tu usuario y contraseña.";
        header("Location: index.php");
        exit();
    }

    $db = conectarDB();
    if (!$db) {
        $_SESSION['error_message'] = "Error de conexión con la base de datos.";
        header("Location: index.php");
        exit();
    }

    try {
        // 3. Buscar al usuario en la tabla 'persona'
        $stmt = $db->prepare("SELECT username, nombre, correo, contrasena FROM persona WHERE username = :username");
        $stmt->bindParam(':username', $username);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // 4. Verificar si el usuario existe Y si la contraseña es correcta (usando password_verify)
        if ($user && password_verify($password, $user['contrasena'])) {
            // ¡Contraseña correcta!
            
            // 5. Iniciar la sesión de forma segura
            session_regenerate_id(true); // Previene ataques de fijación de sesión
            
            $_SESSION['loggedin'] = true;
            $_SESSION['username'] = $user['username'];
            $_SESSION['nombre_usuario'] = $user['nombre'];
            $_SESSION['correo_usuario'] = $user['correo'];

            // 6. Redirigir a la página principal
            header("Location: main.php");
            exit();

        } else {
            // Usuario no encontrado o contraseña incorrecta
            $_SESSION['error_message'] = "Nombre de usuario o contraseña incorrectos.";
            header("Location: index.php");
            exit();
        }

    } catch (PDOException $e) {
        error_log("Error en el login: " . $e->getMessage());
        $_SESSION['error_message'] = "Ocurrió un error. Por favor, inténtelo más tarde.";
        header("Location: index.php");
        exit();
    }
}

// Para mostrar mensajes que puedan venir de otros scripts (ej. registro exitoso)
$mensaje_error = $_SESSION['error_message'] ?? null;
$mensaje_success = $_SESSION['success_message'] ?? null;
unset($_SESSION['error_message'], $_SESSION['success_message']);

?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Iniciar Sesión - Plataforma de Viajes</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <main class="container">
        <div class="card">
            <h1>Bienvenido a la Plataforma</h1>

            <?php if ($mensaje_error): ?>
                <p class="error"><?= htmlspecialchars($mensaje_error) ?></p>
            <?php endif; ?>
            <?php if ($mensaje_success): ?>
                <p class="success"><?= htmlspecialchars($mensaje_success) ?></p>
            <?php endif; ?>

            <form action="index.php" method="POST">
                <div class="form-group">
                    <label for="username">Nombre de Usuario:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                <div class="form-group">
                    <label for="password">Contraseña:</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <button type="submit">Iniciar Sesión</button>
            </form>
            <div class="form-footer-link">
                <p>¿No tienes una cuenta? <a href="registro.php">Regístrate aquí</a></p>
            </div>
        </div>
    </main>
</body>
</html>