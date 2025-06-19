<?php
session_start();
// Para mostrar mensajes de error/éxito que vienen de procesar_registro.php
$mensaje_error = $_SESSION['error_message'] ?? null;
$mensaje_success = $_SESSION['success_message'] ?? null;
unset($_SESSION['error_message'], $_SESSION['success_message']);
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registro - Plataforma de Viajes</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <main class="container">
        <div class="card">
            <h1>Crear una Cuenta</h1>

            <?php if ($mensaje_error): ?>
                <p class="error"><?= htmlspecialchars($mensaje_error) ?></p>
            <?php endif; ?>

            <form action="procesar_registro.php" method="POST">
                <div class="form-group">
                    <label for="nombre">Nombre Completo:</label>
                    <input type="text" id="nombre" name="nombre" required>
                </div>
                <div class="form-group">
                    <label for="username">Nombre de Usuario:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                <div class="form-group">
                    <label for="correo">Correo Electrónico:</label>
                    <input type="email" id="correo" name="correo" required>
                </div>
                <div class="form-group">
                    <label for="password">Contraseña:</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <div class="form-group">
                    <label for="password_confirm">Confirmar Contraseña:</label>
                    <input type="password" id="password_confirm" name="password_confirm" required>
                </div>
                <div class="form-group">
                    <label for="run">RUN (sin puntos ni guión):</label>
                    <input type="text" id="run" name="run" placeholder="Ej: 12345678" required>
                </div>
                 <div class="form-group">
                    <label for="dv">Dígito Verificador (DV):</label>
                    <input type="text" id="dv" name="dv" placeholder="Ej: k" required>
                </div>
                 <div class="form-group">
                    <label for="telefono">Teléfono (opcional):</label>
                    <input type="text" id="telefono" name="telefono" placeholder="+56912345678">
                </div>
                <button type="submit">Registrarme</button>
            </form>
            <div class="form-footer-link">
                <p>¿Ya tienes una cuenta? <a href="index.php">Inicia sesión</a></p>
            </div>
        </div>
    </main>
</body>
</html>