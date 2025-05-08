<?php
require_once "funciones.php";

$rutaUsuarios = "../CSV_sucios/usuarios_rescatados.csv";
$rutaEmpleados = "../CSV_sucios/empleados_rescatados.csv";

Cargar($rutaUsuarios);
Cargar($rutaEmpleados);

GuardarCSV(array_values($personas), "personasOK.csv");
GuardarCSV(array_values($usuarios), "usuariosOK.csv");
GuardarCSV(array_values($empleados), "empleadosOK.csv");
GuardarCSV(array_values($agendas), "agendasOK.csv");

GuardarCSV(array_values($reservas), "reservasOK.csv");

GuardarCSV(array_values($transportes), "transportesOK.csv");

GuardarCSV(array_values($buses), "busesOK.csv");

GuardarCSV(array_values($trenes), "trenesOK.csv");

GuardarCSV(array_values($aviones), "avionesOK.csv");

GuardarDatosDescartados();

echo "Proceso completado. Revisar en la carpeta CSV_limpios todos los archivos creados :D.\n";
?>
