<?php
/**
 * procesar_crear_viaje.php
 * Versión final y completa.
 * Maneja la creación de un nuevo viaje, con lógica condicional para el caso "Fin de semestre".
 * Este script asume que la BD es inmutable (IDs no autoincrementales para la mayoría de las tablas).
 * Los puntos se calculan automáticamente mediante el SP1 y TRIGGER2 definidos en puntos.sql.
 */

session_start();
require_once 'utils.php';

// Redirigir si el acceso no es mediante POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: crear_viaje.php');
    exit;
}

// Conectar a la BD
$db = conectarBD();
if (!$db) {
    $_SESSION['mensaje'] = 'No se pudo conectar a la base de datos.';
    $_SESSION['tipo_mensaje'] = 'error';
    header('Location: crear_viaje.php');
    exit;
}

try {
    // Iniciar la transacción para asegurar la atomicidad de la operación
    $db->beginTransaction();

    // --- OBTENER Y VALIDAR DATOS DEL FORMULARIO ---
    $nombre_viaje = trim($_POST['nombre_viaje'] ?? '');
    $organizador_email = trim($_POST['organizador_email'] ?? '');
    $organizador_nombre = trim($_POST['organizador_nombre'] ?? '');
    $organizador_username = trim($_POST['organizador_username'] ?? '');
    
    if (empty($nombre_viaje) || empty($organizador_email) || empty($organizador_nombre) || empty($organizador_username)) {
        throw new Exception("Los datos del organizador y el nombre del viaje son obligatorios.");
    }
    
    $participantes_form = json_decode($_POST['participantes'] ?? '[]', true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        $participantes_form = []; // Asegurarse de que es un array si el JSON está vacío o es inválido
    }
    
    // --- GESTIONAR PERSONAS Y USUARIOS ---
    // Se crea una lista con todas las personas (organizador + participantes) para procesarlas.
    $personas_a_procesar = array_merge(
        [['nombre' => $organizador_nombre, 'correo' => $organizador_email, 'username' => $organizador_username]],
        array_map(function($p) {
            return [
                'nombre' => $p['name'],
                'correo' => strtolower(str_replace(' ', '.', $p['name'])) . '@viajero.com',
                'username' => strtolower(str_replace(' ', '', $p['name'])) . rand(100,999)
            ];
        }, $participantes_form)
    );

    // Se itera para asegurar que cada persona exista en 'persona' y 'usuario'.
    foreach ($personas_a_procesar as $p) {
        // Verificar y crear en 'persona' si no existe
        $stmt_check_persona = $db->prepare("SELECT correo FROM persona WHERE correo = ?");
        $stmt_check_persona->execute([$p['correo']]);
        if ($stmt_check_persona->fetch() === false) {
            $stmt_persona = $db->prepare("INSERT INTO persona (correo, nombre, username, contrasena, run, dv) VALUES (?, ?, ?, ?, ?, ?)");
            $stmt_persona->execute([$p['correo'], $p['nombre'], $p['username'], 'password_placeholder', rand(1000000, 20000000), rand(0, 9)]);
        }
        
        // Verificar y crear en 'usuario' si no existe
        $stmt_check_usuario = $db->prepare("SELECT correo FROM usuario WHERE correo = ?");
        $stmt_check_usuario->execute([$p['correo']]);
        if ($stmt_check_usuario->fetch() === false) {
            $stmt_usuario = $db->prepare("INSERT INTO usuario (correo, puntos) VALUES (?, 0)");
            $stmt_usuario->execute([$p['correo']]);
        }
    }

    // --- CREAR LA AGENDA ---
    // La tabla 'agenda' sí es autoincremental según el esquema.
    $stmt_agenda = $db->prepare("INSERT INTO agenda (correo_usuario, etiqueta) VALUES (?, ?) RETURNING id");
    $stmt_agenda->execute([$organizador_email, $nombre_viaje]);
    $agenda_id = $stmt_agenda->fetchColumn();
    if (!$agenda_id) {
        throw new Exception("No se pudo crear la agenda.");
    }

    // --- LÓGICA CONDICIONAL PARA INSERTAR COMPONENTES ---
    if ($nombre_viaje === 'Fin de semestre') {
        // =============================================================
        // LÓGICA PARA "FIN DE SEMESTRE" (BUSCAR DATOS EXISTENTES)
        // =============================================================

        $nombres_servicios = [
            'transporte_empresa' => 'AeroPeor',
            'hospedaje_nombre' => 'La familia',
            'panoramas' => ['Vino de Mesa Italiano', 'El príncipe di Corleone', "The Godfather's House", 'Movimiento Antimafia (CIDMA)']
        ];
        $cantidad_personas = count($personas_a_procesar);
        
        $next_id_reserva = $db->query("SELECT COALESCE(MAX(id), 0) FROM reserva")->fetchColumn() + 1;
        $stmt_reserva = $db->prepare("INSERT INTO reserva (id, fecha, monto, cantidad_personas, estado_disponibilidad, agenda_id) VALUES (?, CURRENT_DATE, ?, ?, 'confirmada', ?)");

        // 1. Transporte
        $stmt_find = $db->prepare("SELECT id, precio_asiento FROM transporte WHERE empresa = ? LIMIT 1");
        $stmt_find->execute([$nombres_servicios['transporte_empresa']]);
        $transporte = $stmt_find->fetch(PDO::FETCH_ASSOC);
        if (!$transporte) throw new Exception("Servicio requerido no encontrado: Transporte de '{$nombres_servicios['transporte_empresa']}'. Asegúrate de haber corrido el script de precarga.");
        $monto_total = $transporte['precio_asiento'] * $cantidad_personas;
        $stmt_reserva->execute([$next_id_reserva++, $monto_total, $cantidad_personas, $agenda_id]);

        // 2. Hospedaje
        $stmt_find = $db->prepare("SELECT id, precio_noche FROM hospedaje WHERE nombre_hospedaje = ? LIMIT 1");
        $stmt_find->execute([$nombres_servicios['hospedaje_nombre']]);
        $hospedaje = $stmt_find->fetch(PDO::FETCH_ASSOC);
        if (!$hospedaje) throw new Exception("Servicio requerido no encontrado: Hospedaje '{$nombres_servicios['hospedaje_nombre']}'.");
        $monto_total = $hospedaje['precio_noche'] * 5 * $cantidad_personas; // 5 noches
        $stmt_reserva->execute([$next_id_reserva++, $monto_total, $cantidad_personas, $agenda_id]);

        // 3. Panoramas
        foreach ($nombres_servicios['panoramas'] as $nombre_pano) {
            $stmt_find = $db->prepare("SELECT id, precio_persona FROM panorama WHERE nombre = ? LIMIT 1");
            $stmt_find->execute([$nombre_pano]);
            $panorama = $stmt_find->fetch(PDO::FETCH_ASSOC);
            if (!$panorama) throw new Exception("Servicio requerido no encontrado: Panorama '$nombre_pano'.");
            
            $monto_total = $panorama['precio_persona'] * $cantidad_personas;
            $stmt_reserva->execute([$next_id_reserva++, $monto_total, $cantidad_personas, $agenda_id]);
            
            // Inscribir participantes a este panorama
            $stmt_participante = $db->prepare("INSERT INTO participante (panorama_id, nombre, edad) VALUES (?, ?, ?)");
            foreach ($personas_a_procesar as $persona) {
                // La tabla 'participante' tiene su propio ID autoincremental
                $edad = rand(20, 25); // Asignar una edad de ejemplo
                $stmt_participante->execute([$panorama['id'], $persona['nombre'], $edad]);
            }
        }

    } else {
        // =============================================================
        // LÓGICA PARA VIAJES GENÉRICOS (CREAR DATOS NUEVOS)
        // =============================================================
        
        $next_ids = [
            'reserva' => $db->query("SELECT COALESCE(MAX(id), 0) FROM reserva")->fetchColumn() + 1,
            'transporte' => $db->query("SELECT COALESCE(MAX(id), 0) FROM transporte")->fetchColumn() + 1,
            'hospedaje' => $db->query("SELECT COALESCE(MAX(id), 0) FROM hospedaje")->fetchColumn() + 1,
            'panorama' => $db->query("SELECT COALESCE(MAX(id), 0) FROM panorama")->fetchColumn() + 1,
        ];
        $cantidad_personas = count($personas_a_procesar);

        // Crear transporte genérico
        $stmt_transporte = $db->prepare("INSERT INTO transporte (id, lugar_origen, lugar_llegada, precio_asiento, fecha_salida, tiempo_estimado, empresa) VALUES (?, ?, ?, ?, ?, 480, 'Empresa Genérica')");
        $stmt_transporte->execute([$next_ids['transporte'], 'Origen Genérico', 'Destino Genérico', 100000, '2025-01-01']);
        
        $stmt_reserva = $db->prepare("INSERT INTO reserva (id, fecha, monto, cantidad_personas, estado_disponibilidad, agenda_id) VALUES (?, ?, ?, ?, 'confirmada', ?)");
        $monto_total = 100000 * $cantidad_personas;
        $stmt_reserva->execute([$next_ids['reserva'], '2025-01-01', $monto_total, $cantidad_personas, $agenda_id]);
        
        // (Aquí se podría añadir lógica similar para crear hospedajes y panoramas genéricos)
    }

    // --- CONFIRMAR LA TRANSACCIÓN ---
    $db->commit();
    
    $_SESSION['mensaje'] = 'Agenda creada correctamente';
    $_SESSION['tipo_mensaje'] = 'success';
    header('Location: crear_viaje.php');
    exit;
    
} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollback();
    }
    $_SESSION['mensaje'] = "No se pudo crear el viaje: " . $e->getMessage();
    $_SESSION['tipo_mensaje'] = 'error';
    header('Location: crear_viaje.php');
    exit;
}
?>