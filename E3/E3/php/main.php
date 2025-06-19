<?php
session_start();

if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
    header("Location: index.php");
    exit();
}

require_once 'utils.php';

$db = get_db_connection();
$agendas = [];
$error_db = null;

// --- LÓGICA DE PAGINACIÓN ---
$items_por_pagina = 10;
$pagina_actual = isset($_GET['pagina']) ? (int)$_GET['pagina'] : 1;
if ($pagina_actual < 1) {
    $pagina_actual = 1;
}
$offset = ($pagina_actual - 1) * $items_por_pagina;
$total_paginas = 0;

if ($db) {
    try {
        // Contar el total de agendas para la paginación
        $total_items_stmt = $db->query("SELECT COUNT(*) FROM agenda");
        $total_items = (int)$total_items_stmt->fetchColumn();
        $total_paginas = ceil($total_items / $items_por_pagina);

        // --- Consulta a la vista corregida ---
        $query = "
            SELECT
                agenda_id,
                nombre_viaje, -- Ahora esta columna sí existe en la vista
                nombre_organizador,
                correo_organizador
            FROM
                vista_organizador_agenda
            ORDER BY
                agenda_id DESC
            LIMIT :limit OFFSET :offset
        ";
        
        $stmt = $db->prepare($query);
        $stmt->bindValue(':limit', $items_por_pagina, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();
        
        $agendas = $stmt->fetchAll(PDO::FETCH_ASSOC);

    } catch (PDOException $e) {
        $error_db = "Error al cargar los viajes: " . $e->getMessage();
        error_log($error_db);
    } finally {
        $db = null;
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Página Principal - Plataforma de Viajes</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <header class="header">
        <div class="container">
            <h1>Plataforma de Viajes</h1>
            <nav class="nav">
                <span class="welcome-msg">Bienvenido/a, <?php echo htmlspecialchars($_SESSION['nombre_usuario']); ?></span>
                <a href="crear_viaje.php" class="btn">Crear un Nuevo Viaje</a>
                <a href="cerrar_sesion.php" class="btn btn-logout">Cerrar Sesión</a>
            </nav>
        </div>
    </header>

    <main class="container">
        <div class="card">
            <h2>Agendas de Viaje Creadas</h2>
        
            <?php if ($error_db): ?>
                <p class="error"><?php echo htmlspecialchars($error_db); ?></p>
            <?php endif; ?>

            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Nombre del Viaje</th>
                            <th>Organizador</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($agendas)): ?>
                            <tr>
                                <td colspan="3">No hay agendas de viaje creadas.</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($agendas as $agenda): ?>
                                <tr>
                                    <td><?php echo htmlspecialchars($agenda['nombre_viaje']); ?></td>
                                    <td><?php echo htmlspecialchars($agenda['nombre_organizador']); ?></td>
                                    <td>
                                        <a href="desplegar_viaje.php?id=<?php echo $agenda['agenda_id']; ?>" class="btn-small">Ver Detalles</a>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>

            <?php if ($total_paginas > 1): ?>
            <div class="paginacion">
                <?php if ($pagina_actual > 1): ?>
                    <a href="?pagina=<?php echo $pagina_actual - 1; ?>">Anterior</a>
                <?php else: ?>
                    <a href="#" class="disabled">Anterior</a>
                <?php endif; ?>

                <span>Página <?php echo $pagina_actual; ?> de <?php echo $total_paginas; ?></span>

                <?php if ($pagina_actual < $total_paginas): ?>
                    <a href="?pagina=<?php echo $pagina_actual + 1; ?>">Siguiente</a>
                <?php else: ?>
                    <a href="#" class="disabled">Siguiente</a>
                <?php endif; ?>
            </div>
            <?php endif; ?>
        </div>
    </main>

    <footer class="footer">
        <p>&copy; <?php echo date('Y'); ?> Plataforma de Viajes</p>
    </footer>
</body>
</html>