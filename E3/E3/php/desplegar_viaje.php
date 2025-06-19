<?php
session_start();
if (!isset($_SESSION['loggedin'])) { header("Location: index.php"); exit(); }

require_once 'utils.php';
$agenda_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($agenda_id === 0) die("Error: No se ha especificado un ID de viaje válido.");

$agenda_info = null;
$reservas_viaje = [];
$transportes_filtrados = []; // Array para guardar los transportes filtrados
$error = '';

try {
    $db = get_db_connection();
    
    // 1. Obtener información específica de ESTA agenda (sin cambios)
    $stmt_info = $db->prepare("SELECT * FROM vista_info_agenda WHERE agenda_id = :id");
    $stmt_info->execute([':id' => $agenda_id]);
    $agenda_info = $stmt_info->fetch(PDO::FETCH_ASSOC);
    
    // 2. Obtener las reservas específicas de ESTA agenda (sin cambios)
    $stmt_reservas = $db->prepare("SELECT id, fecha, monto, cantidad_personas, estado_disponibilidad FROM reserva WHERE agenda_id = :id ORDER BY monto DESC");
    $stmt_reservas->execute([':id' => $agenda_id]);
    $reservas_viaje = $stmt_reservas->fetchAll(PDO::FETCH_ASSOC);

    // ===================================================================
    // INICIO DE LA NUEVA LÓGICA DE FILTRADO
    // ===================================================================
    if (!empty($reservas_viaje)) {
        // 3. Extraer todos los montos de las reservas de este viaje
        $montos_reservas = array_column($reservas_viaje, 'monto');
        
        // Creamos los placeholders (?) para la consulta IN. Ej: (?, ?, ?)
        $placeholders = implode(',', array_fill(0, count($montos_reservas), '?'));

        // 4. Consultar la tabla de transportes, filtrando por los montos
        // Se asume una relación donde el monto de la reserva puede coincidir con el precio del asiento.
        // NOTA: Esta es una deducción lógica, no un JOIN directo.
        $stmt_transportes = $db->prepare(
            "SELECT id, empresa, lugar_origen, lugar_llegada, precio_asiento 
             FROM transporte 
             WHERE precio_asiento IN ($placeholders)"
        );
        $stmt_transportes->execute($montos_reservas);
        $transportes_filtrados = $stmt_transportes->fetchAll(PDO::FETCH_ASSOC);
    }
    // ===================================================================
    // FIN DE LA NUEVA LÓGICA
    // ===================================================================

} catch (Exception $e) {
    $error = "Error al consultar la información del viaje: " . $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Detalles del Viaje</title>
    <link rel="stylesheet" href="../css/style.css"> 
</head>
<body>
    <header class="header">
        <div class="container"><h1>Detalles del Viaje</h1><nav><a href="main.php" class="btn">Volver a Principal</a></nav></div>
    </header>

    <main class="container">
        <div class="card">
            <?php if ($error): ?>
                <p class="error"><?= htmlspecialchars($error) ?></p>
            <?php elseif ($agenda_info): ?>
                
                <fieldset>
                    <legend>Información General del Viaje</legend>
                    <h2>Viaje: <?= htmlspecialchars($agenda_info['nombre_viaje']) ?> (ID: <?= htmlspecialchars($agenda_id) ?>)</h2>
                    <p><strong>Organizador:</strong> <?= htmlspecialchars($agenda_info['nombre_organizador']) ?> (<?= htmlspecialchars($agenda_info['correo_organizador']) ?>)</p>
                </fieldset>

                <fieldset>
                    <legend>Reservas Realizadas para este Viaje</legend>
                    <?php if(empty($reservas_viaje)): ?>
                        <p>No se encontraron reservas para esta agenda.</p>
                    <?php else: ?>
                    <div class="table-container">
                        <table>
                           <thead><tr><th>Id Reserva</th><th>Monto</th><th>Personas</th></tr></thead>
                           <tbody>
                            <?php foreach($reservas_viaje as $reserva): ?>
                            <tr>
                                <td><?= htmlspecialchars($reserva['id'])?></td>
                                <td>$<?= htmlspecialchars(number_format($reserva['monto']))?></td>
                                <td><?= htmlspecialchars($reserva['cantidad_personas'])?></td>
                            </tr>
                            <?php endforeach; ?>
                           </tbody>
                        </table>
                    </div>
                    <?php endif; ?>
                </fieldset>
                
                <fieldset>
                    <legend>Transportes Asociados a este Viaje</legend>
                    <p><i>NOTA: Transportes deducidos lógicamente a través del monto de las reservas.</i></p>
                    <?php if(empty($transportes_filtrados)): ?>
                        <p>No se encontraron transportes asociados a las reservas de este viaje.</p>
                    <?php else: ?>
                    <div class="table-container">
                        <table>
                           <thead><tr><th>Empresa</th><th>Origen</th><th>Destino</th><th>Precio Asiento</th></tr></thead>
                           <tbody>
                            <?php foreach($transportes_filtrados as $transporte): ?>
                            <tr>
                                <td><?= htmlspecialchars($transporte['empresa'])?></td>
                                <td><?= htmlspecialchars($transporte['lugar_origen'])?></td>
                                <td><?= htmlspecialchars($transporte['lugar_llegada'])?></td>
                                <td>$<?= htmlspecialchars(number_format($transporte['precio_asiento']))?></td>
                            </tr>
                            <?php endforeach; ?>
                           </tbody>
                        </table>
                    </div>
                    <?php endif; ?>
                </fieldset>
                <?php else: ?>
                <p>No se encontró información para el viaje con ID <?= htmlspecialchars($agenda_id) ?>.</p>
            <?php endif; ?>
        </div>
    </main>
</body>
</html>