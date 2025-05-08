<?php

ini_set("memory_limit", "256M");

$personas = [];
$usuarios = [];
$empleados = [];
$agendas = [];
$reservas = [];
$transportes = [];
$buses = [];
$trenes = [];
$aviones = [];
$datos_descartados = [];

function Cargar($rutaArchivo) {
    global $personas, $usuarios, $empleados, $agendas, $reservas, $transportes, $buses, $trenes, $aviones, $datos_descartados;
    
    if (($handle = fopen($rutaArchivo, "r")) !== FALSE) {
        $encabezado = fgetcsv($handle, 1000, ",");
        if ($encabezado === FALSE || count($encabezado) < 2) {
            fclose($handle);
            return;
        }
        $encabezado = array_map("Encabezado", $encabezado);
        while (($fila = fgetcsv($handle, 1000, ",")) !== FALSE) {
            $fila = array_map("trim", $fila);
            if (count($encabezado) === count($fila)) {
                try {
                    $data = array_combine($encabezado, $fila);
                    $data = Limpiar($data);
                    if (Validar($data, basename($rutaArchivo))) {
                        ManejoDatos($data, basename($rutaArchivo));
                    } else {
                        $datos_descartados[] = $data;
                    }
                } catch (Exception $error) {
                }
            }
        }
        fclose($handle);
    }
}

function Encabezado($encabezado) {
    $encabezado = trim($encabezado);
    $encabezado = str_replace(":", "", $encabezado);
    $encabezado = preg_replace("/\s+/", " ", $encabezado);
    $encabezado = preg_replace("/^\xEF\xBB\xBF/", "", $encabezado);
    return $encabezado;
}

function Validar($fila, $archivo) {
    $valido = true;
    if (!isset($fila["correo"]) || trim($fila["correo"]) === "" || !filter_var($fila["correo"], FILTER_VALIDATE_EMAIL)) {
        return false;
    }
    if (!isset($fila["run"]) || trim($fila["run"]) === "" || !is_numeric($fila["run"]) || intval($fila["run"]) <= 0) {
        return false;
    }
    if (!isset($fila["nombre"]) || trim($fila["nombre"]) === "") {
        return false;
    }
    if (!isset($fila["dv"]) || trim($fila["dv"]) === "" || !preg_match('/^[0-9Kk]$/', $fila["dv"])) {
        return false;
    }
    
    if ($archivo == "usuarios_rescatados.csv") {
        if (!isset($fila["codigo_agenda"]) || trim($fila["codigo_agenda"]) === "" || !is_numeric($fila["codigo_agenda"])) {
            return false;
        }
        if (!isset($fila["etiqueta"]) || trim($fila["etiqueta"]) === "") {
            return false;
        }
        if (!isset($fila["cantidad_personas"]) || !is_numeric($fila["cantidad_personas"]) || intval($fila["cantidad_personas"]) <= 0) {
            return false;
        }
        
    } elseif ($archivo == "empleados_rescatados.csv") {
        if (!isset($fila["jornada"]) || trim($fila["jornada"]) === "") {
            return false;
        }
        if (!isset($fila["contrato"]) || trim($fila["contrato"]) === "") {
            return false;
        }
        if (!isset($fila["numero_viaje"]) || trim($fila["numero_viaje"]) === "" || !is_numeric($fila["numero_viaje"])) {
            return false;
        }
        if (!isset($fila["lugar_origen"]) || trim($fila["lugar_origen"]) === "") {
            return false;
        }
        if (!isset($fila["lugar_llegada"]) || trim($fila["lugar_llegada"]) === "") {
            return false;
        }
        if (isset($fila["tipo_de_bus"]) && trim($fila["tipo_de_bus"]) !== "") {
        } 
        else if (isset($fila["paradas"]) && trim($fila["paradas"]) !== "" && $fila["paradas"] !== "{}") {
        }
        else if ((isset($fila["escalas"]) && trim($fila["escalas"]) !== "" && $fila["escalas"] !== "{}") || 
                 (isset($fila["clase"]) && trim($fila["clase"]) !== "")) {
            if (!isset($fila["escalas"]) || trim($fila["escalas"]) === "" || $fila["escalas"] === "{}") {
                return false;
            }
        }
    }
    
    return $valido;
}

function Limpiar($fila) {
    $fila_limpia = [];
    foreach ($fila as $clave => $valor) {
        $valor_limpio = trim($valor);
        if (empty($valor_limpio) && $valor_limpio !== "0") {
            $valor_final = "x";
        } else {
            $valor_final = $valor_limpio;
        }
        $fila_limpia[$clave] = $valor_final;
    }
    return $fila_limpia;
}

#este no sé si está bien xd
#si estaba
function NormalizarFecha($fecha) {
    if (preg_match('/^\d{4}\/\d{2}\/\d{2}$/', $fecha)) {
        return str_replace('/', '-', $fecha);
    }
    return $fecha;
}


function ManejoDatos($fila, $archivo) {
    global $personas, $usuarios, $empleados, $agendas, $reservas, $transportes, $buses, $trenes, $aviones;
    
    if ($archivo == "usuarios_rescatados.csv") {
        if (Validar($fila, $archivo)) {
            $persona = [
                "nombre" => $fila["nombre"],
                "run" => $fila["run"],
                "dv" => $fila["dv"],
                "nombre_usuario" => $fila["nombre_usuario"],
                "correo" => $fila["correo"],
                "contrasena" => $fila["contrasena"],
                "telefono_contacto" => $fila["telefono_contacto"],
            ];
            $personas[$fila["correo"]] = $persona;
            
            $usuario = [
                "nombre" => $fila["nombre"],
                "run" => $fila["run"],
                "dv" => $fila["dv"],
                "correo" => $fila["correo"],
                "contrasena" => $fila["contrasena"],
                "nombre_usuario" => $fila["nombre_usuario"],
                "telefono_contacto" => $fila["telefono_contacto"],
                "puntos" => $fila["puntos"],
            ];
            $usuarios[$fila["correo"]] = $usuario;
            
            #es normalizar fecha o date?
            $agenda = [
                "correo_usuario" => $fila["correo"],
                "codigo_agenda" => $fila["codigo_agenda"],
                "etiqueta" => $fila["etiqueta"],
                "fecha_creacion" => date('Y-m-d')
            ];
            $agendas[$fila["correo"]] = $agenda;
            
            $reserva = [
                "codigo_agenda" => $fila["codigo_agenda"],
                "codigo_reserva" => $fila["codigo_reserva"],
                "fecha" => NormalizarFecha($fila["fecha"]),
                "monto" => $fila["monto"],
                "cantidad_personas" => $fila["cantidad_personas"],
            ];
            $reservas[$fila["codigo_reserva"]] = $reserva;
        }
    } elseif ($archivo == "empleados_rescatados.csv") {
        if (Validar($fila, $archivo)) {
            $persona = [
                "nombre" => $fila["nombre"],
                "run" => $fila["run"],
                "dv" => $fila["dv"],
                "correo" => $fila["correo"],
                "contrasena" => $fila["contrasena"],
                "nombre_usuario" => $fila["nombre_usuario"],
                "telefono_contacto" => $fila["telefono_contacto"],
            ];
            $personas[$fila["correo"]] = $persona;
            
            $empleado = [
                "nombre" => $fila["nombre"],
                "run" => $fila["run"],
                "dv" => $fila["dv"],
                "correo" => $fila["correo"],
                "contrasena" => $fila["contrasena"],
                "nombre_usuario" => $fila["nombre_usuario"],
                "telefono_contacto" => $fila["telefono_contacto"],
                "jornada" => $fila["jornada"],
                "isapre" => $fila["isapre"],
                "contrato" => $fila["contrato"],
            ];
            $empleados[$fila["correo"]] = $empleado;
            

            #está bien el tema de codigo_reserva? está dos veces, revisasr
            $transporte_general = [
                "codigo_reserva" => $fila["codigo_reserva"],
                "correo_empleado" => $fila["correo"],
                "numero_viaje" => $fila["numero_viaje"],
                "lugar_origen" => $fila["lugar_origen"],
                "lugar_llegada" => $fila["lugar_llegada"],
                "capacidad" => $fila["capacidad"],
                "tiempo_estimado" => $fila["tiempo_estimado"],
                "precio_asiento" => $fila["precio_asiento"],
                "empresa" => $fila["empresa"]
            ];
            $transportes[$fila["codigo_reserva"]] = $transporte_general;
            
            if (!empty(trim($fila["tipo_de_bus"])) && $fila["tipo_de_bus"] !== "x") {
                $bus = $transporte_general;
                $bus["tipo"] = $fila["tipo_de_bus"];
                $bus["comodidades"] = $fila["comodidades"];
                $buses[$fila["codigo_reserva"]] = $bus;
            }
            
            if (!empty(trim($fila["paradas"])) && $fila["paradas"] !== "{}" && $fila["paradas"] !== "x") {
                $tren = $transporte_general;
                $tren["comodidades"] = $fila["comodidades"];
                $tren["paradas"] = $fila["paradas"];
                $trenes[$fila["codigo_reserva"]] = $tren;
            }

            if (
                (!empty(trim($fila["escalas"])) && $fila["escalas"] !== "{}" && $fila["escalas"] !== "x") ||
                (!empty(trim($fila["clase"])) && $fila["clase"] !== "x")
            ) {
                $avion = $transporte_general;
                $avion["escalas"] = $fila["escalas"];
                $avion["clase"] = $fila["clase"] ?? "";;
                $aviones[$fila["codigo_reserva"]] = $avion;
            }
        }
    }
}

function GuardarCSV($datos, $nombre_archivo) {
    $directorioSalida = "../CSV_limpios";

    if (!is_dir($directorioSalida)) {
        mkdir($directorioSalida, 0777, true);
    }

    $rutaSalida = $directorioSalida . "/" . $nombre_archivo;

    if (empty($datos)) {
        echo "No hay datos para guardar en $rutaSalida.\n";
        return;
    }

    $archivo = fopen($rutaSalida, "w");
    if ($archivo) {
        fputcsv($archivo, array_keys($datos[0]));
        foreach ($datos as $fila) {
            fputcsv($archivo, $fila);
        }
        fclose($archivo);
        echo "Archivo guardado: $rutaSalida\n";
    } else {
        echo "Error al abrir el archivo $rutaSalida para escritura.\n";
    }
}

function GuardarDatosDescartados() {
    global $datos_descartados;
    GuardarCSV($datos_descartados, "datos_descartados.csv");
}
?>
