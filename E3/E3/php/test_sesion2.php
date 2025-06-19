<?php
session_start();
$mensaje = $_SESSION['mensaje_prueba'] ?? 'ERROR: NO SE PUDO LEER EL MENSAJE DE LA SESIÓN.';
echo $mensaje;
?>