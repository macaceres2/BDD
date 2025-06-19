<?php
session_start();
require_once 'utils.php';

// --- Configuración del Viaje Específico "Fin de semestre" ---
$datos_organizador = ['nombre' => 'Lucas Viajero', 'correo' => 'lucasviajero@uc.cl', 'username' => 'lucasviajero'];
$etiqueta_viaje = 'Fin de semestre';

// Nombres de los servicios que DEBEN existir previamente en tu base de datos
$nombre_empresa_transporte = 'AeroPeor'; // Usamos la empresa, como en el relato
$nombre_hospedaje = 'La familia';
$nombres_panoramas = [
    'Vino de Mesa Italiano',
    'El príncipe di Corleone',
    "The Godfather's House",
    'Movimiento Antimafia (CIDMA)'
];
$participantes_panorama = [['nombre' => 'Ana Torres', 'edad' => 22], ['nombre' => 'Carlos Soto', 'edad' => 23]];

// --- Comienza la Salida HTML ---
echo "<!DOCTYPE html><html lang='es'><head><title>Creando Viaje</title><link rel='stylesheet' href='../css/style.css'></head><body><main class='container'><div class='card'>";
echo "<h1>Creando el viaje 'Fin de semestre'...</h1>";

$db = get_db_connection();
if (!$db) {
    die("<p class='error'>Error de conexión a la base de datos.</p></div></main></body></html>");
}

try {
    $db->beginTransaction();
    echo "<p>Iniciando transacción...</p>";

    // 1. Crear el usuario "Lucas Viajero" si no existe
    $stmt_check = $db->prepare("SELECT correo FROM persona WHERE correo = ?");
    $stmt_check->execute([$datos_organizador['correo']]);
    if ($stmt_check->fetch() === false) {
        $stmt_persona = $db->prepare("INSERT INTO persona (correo, nombre, contrasena, username, run, dv) VALUES (?, ?, ?, ?, 12345678, '9')");
        $stmt_persona->execute([$datos_organizador['correo'], $datos_organizador['nombre'], 'password_placeholder', $datos_organizador['username']]);
        $stmt_usuario = $db->prepare("INSERT INTO usuario (correo, puntos) VALUES (?, 0)");
        $stmt_usuario->execute([$datos_organizador['correo']]);
        echo "<p>Usuario 'Lucas Viajero' creado.</p>";
    } else {
        echo "<p>Usuario 'Lucas Viajero' ya existía.</p>";
    }

    // 2. Crear la Agenda
    $stmt_agenda = $db->prepare("INSERT INTO agenda (correo_usuario, etiqueta) VALUES (?, ?) RETURNING id");
    $stmt_agenda->execute([$datos_organizador['correo'], $etiqueta_viaje]);
    $agenda_id = $stmt_agenda->fetchColumn();
    echo "<p>Agenda 'Fin de semestre' creada con ID: $agenda_id.</p>";

    // 3. Encontrar servicios existentes y crear reservas
    $next_id_reserva = $db->query("SELECT COALESCE(MAX(id), 0) FROM reserva")->fetchColumn() + 1;

    // Transporte
    $stmt_find_trans = $db->prepare("SELECT id, precio_asiento FROM transporte WHERE empresa = ? LIMIT 1");
    $stmt_find_trans->execute([$nombre_empresa_transporte]);
    $transporte = $stmt_find_trans->fetch(PDO::FETCH_ASSOC);
    if (!$transporte) throw new Exception("El transporte de la empresa '$nombre_empresa_transporte' no está definido en la BD.");
    $stmt_reserva = $db->prepare("INSERT INTO reserva (id, fecha, monto, agenda_id) VALUES (?, CURRENT_DATE, ?, ?)");
    $stmt_reserva->execute([$next_id_reserva++, $transporte['precio_asiento'], $agenda_id]);
    echo "<p>Reserva para transporte de '{$nombre_empresa_transporte}' creada.</p>";

    // Hospedaje
    $stmt_find_hosp = $db->prepare("SELECT id, precio_noche FROM hospedaje WHERE nombre_hospedaje = ? LIMIT 1");
    $stmt_find_hosp->execute([$nombre_hospedaje]);
    $hospedaje = $stmt_find_hosp->fetch(PDO::FETCH_ASSOC);
    if (!$hospedaje) throw new Exception("El hospedaje '$nombre_hospedaje' no está definido en la BD.");
    $stmt_reserva->execute([$next_id_reserva++, $hospedaje['precio_noche'] * 5, $agenda_id]); // Asumimos 5 noches
    echo "<p>Reserva para hospedaje '{$nombre_hospedaje}' creada.</p>";

    // Panoramas
    foreach($nombres_panoramas as $nombre_pano) {
        $stmt_find_pano = $db->prepare("SELECT id, precio_persona FROM panorama WHERE nombre = ? LIMIT 1");
        $stmt_find_pano->execute([$nombre_pano]);
        $panorama = $stmt_find_pano->fetch(PDO::FETCH_ASSOC);
        if (!$panorama) throw new Exception("El panorama '$nombre_pano' no está definido en la BD.");
        $stmt_reserva->execute([$next_id_reserva++, $panorama['precio_persona'], $agenda_id]);
        echo "<p>Reserva para panorama '{$nombre_pano}' creada.</p>";

        // Opcional: Inscribir participantes a este panorama específico si se requiere
        // La tabla participante parece más para inscribir gente a un panorama puntual que para definir los viajeros de una agenda.
    }

    $db->commit();
    echo "<p class='success'>¡Agenda creada correctamente!</p>";

} catch (Exception $e) {
    $db->rollBack();
    echo "<p class='error'>No se pudo crear el viaje. Error: " . htmlspecialchars($e->getMessage()) . "</p>";
}

echo "<a href='main.php' class='btn'>Volver a la página principal</a>";
echo "</div></main></body></html>";
?>