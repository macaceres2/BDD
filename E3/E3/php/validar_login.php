<?php
// MODO DEPURACIÓN: Activar para ver errores
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

session_start();
require_once 'utils.php';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    
    // CORREGIDO: Cambiar de 'username' y 'password' a 'usuario' y 'contrasena'
    $username = trim($_POST['usuario'] ?? '');
    $password = $_POST['contrasena'] ?? '';

    echo "DEBUG: Datos recibidos<br>";
    echo "Username: '" . htmlspecialchars($username) . "'<br>";
    echo "Password length: " . strlen($password) . "<br><br>";

    if (empty($username) || empty($password)) {
        echo "ERROR: Campos vacíos<br>";
        $_SESSION['error_message'] = "El nombre de usuario y la contraseña son obligatorios.";
        // header("Location: index.php"); // Comentado para debug
        // exit();
        die("Detenido para debug - campos vacíos");
    }

    $db = conectarBD();
    if (!$db) {
        echo "ERROR: No se pudo conectar a la BD<br>";
        $_SESSION['error_message'] = "Error de conexión con la base de datos.";
        // header("Location: index.php"); // Comentado para debug
        // exit();
        die("Detenido para debug - sin conexión BD");
    }

    echo "DEBUG: Conexión a BD exitosa<br>";

    try {
        $stmt = $db->prepare("SELECT nombre, correo, contrasena FROM persona WHERE username = :username");
        $stmt->bindParam(':username', $username);
        $stmt->execute();

        echo "DEBUG: Consulta ejecutada<br>";

        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            echo "DEBUG: Usuario encontrado en BD<br>";
            echo "- Nombre: " . htmlspecialchars($user['nombre']) . "<br>";
            echo "- Correo: " . htmlspecialchars($user['correo']) . "<br>";
            echo "- Hash almacenado: " . substr($user['contrasena'], 0, 30) . "...<br><br>";
            
            $password_match = password_verify($password, $user['contrasena']);
            echo "DEBUG: Verificación de contraseña: " . ($password_match ? "✅ CORRECTA" : "❌ INCORRECTA") . "<br><br>";
            
            if ($password_match) {
                echo "DEBUG: Login exitoso, configurando sesión...<br>";
                
                session_regenerate_id(true);
            
                $_SESSION['loggedin'] = true;
                $_SESSION['username'] = $username;
                $_SESSION['nombre_usuario'] = $user['nombre'];
                $_SESSION['correo_usuario'] = $user['correo'];

                echo "DEBUG: Sesión configurada. Variables de sesión:<br>";
                echo "- loggedin: " . ($_SESSION['loggedin'] ? 'true' : 'false') . "<br>";
                echo "- username: " . $_SESSION['username'] . "<br>";
                echo "- nombre_usuario: " . $_SESSION['nombre_usuario'] . "<br>";
                echo "- correo_usuario: " . $_SESSION['correo_usuario'] . "<br><br>";

                echo "DEBUG: Redirigiendo a main.php...<br>";
                // header("Location: main.php"); // Comentado para debug
                // exit();
                echo '<a href="main.php">IR A MAIN.PHP MANUALMENTE</a>';
                die("Detenido para debug - login exitoso");

            } else {
                echo "DEBUG: Contraseña incorrecta<br>";
                $_SESSION['error_message'] = "Nombre de usuario o contraseña incorrectos.";
                // header("Location: index.php"); // Comentado para debug
                // exit();
                die("Detenido para debug - contraseña incorrecta");
            }
        } else {
            echo "DEBUG: Usuario NO encontrado en la base de datos<br>";
            echo "DEBUG: Verificando qué usuarios existen...<br>";
            
            // Mostrar todos los usuarios para debug
            $stmt_all = $db->query("SELECT username, nombre FROM persona LIMIT 5");
            $all_users = $stmt_all->fetchAll(PDO::FETCH_ASSOC);
            
            echo "Usuarios en la BD:<br>";
            foreach ($all_users as $u) {
                echo "- Username: '" . htmlspecialchars($u['username']) . "', Nombre: '" . htmlspecialchars($u['nombre']) . "'<br>";
            }
            
            $_SESSION['error_message'] = "Nombre de usuario o contraseña incorrectos.";
            // header("Location: index.php"); // Comentado para debug
            // exit();
            die("Detenido para debug - usuario no encontrado");
        }

    } catch (PDOException $e) {
        echo "ERROR PDO: " . $e->getMessage() . "<br>";
        error_log("Error en validar_login.php: " . $e->getMessage());
        $_SESSION['error_message'] = "Ocurrió un error en la base de datos. Inténtelo más tarde.";
        // header("Location: index.php"); // Comentado para debug
        // exit();
        die("Detenido para debug - error PDO");
    } finally {
        $db = null;
    }

} else {
    echo "ERROR: No es una petición POST<br>";
    // header("Location: index.php"); // Comentado para debug
    // exit();
    die("Detenido para debug - no es POST");
}
?>