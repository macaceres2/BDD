<?php
session_start();
$_SESSION['mensaje_prueba'] = "Hola, las sesiones funcionan.";
echo "Mensaje guardado en la sesión. <a href='test_sesion2.php'>Ir a la página 2</a>";
?>