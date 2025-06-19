<?php
session_start();
require_once 'utils.php';

if (!isset($_SESSION['usuario'])) {
    header('Location: index.php?error=Debes iniciar sesión');
    exit();
}

$tablas = [
    'agendas', 'habitaciones', 'participantes', 'aviones', 'reservas',
    'airbnb', 'buses', 'trenes', 'reviews', 'personas', 'panoramas',
    'usuarios', 'transportes', 'seguros', 'empleados', 'hospedajes', 'hoteles'
];

$tablaSel = $_POST['tabla'] ?? '';
$columnaSel = trim($_POST['columna'] ?? '');
$whereCampo = trim($_POST['where_campo'] ?? '');
$whereValor = trim($_POST['where_valor'] ?? '');

$resultados = [];
$error = '';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (!in_array($tablaSel, $tablas)) {
        $error = "Error: La tabla seleccionada no es válida.";
    } elseif (empty($columnaSel)) {
        $error = "Error: Debes especificar al menos una columna para mostrar.";
    } else {
        $columnaSegura = preg_replace('/[^a-zA-Z0-9_*,]/', '', $columnaSel);
        
        $sql = "SELECT $columnaSegura FROM $tablaSel";
        $params = [];

        if (!empty($whereCampo) && isset($whereValor)) {
            $whereCampoSeguro = preg_replace('/[^a-zA-Z0-9_]/', '', $whereCampo);
            $sql .= " WHERE $whereCampoSeguro = :valor";
            $params[':valor'] = $whereValor;
        }

        try {
            $db = conectarDB();
            $stmt = $db->prepare($sql);
            $stmt->execute($params);
            $resultados = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            if (empty($resultados)) {
                $error = "La consulta no arrojó resultados.";
            }
        } catch (Exception $e) {
            $error = "Error en la consulta. Verifica que los nombres de las columnas sean correctos.";
        }
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Consulta Inestructurada Guiada</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
<div class="container">
    <h1>Consulta Inestructurada Guiada</h1>

    <form method="POST" action="consulta.php" class="formulario">
        <div class="form-group">
            <label for="columna">Columna(s) a mostrar (SELECT):</label>
            <input type="text" name="columna" id="columna" required value="<?= htmlspecialchars($columnaSel) ?>" placeholder="Ej: nombre, correo o *">
        </div>

        <div class="form-group">
            <label for="tabla">Tabla (FROM):</label>
            <select name="tabla" id="tabla" required>
                <option value="">-- Seleccionar tabla --</option>
                <?php foreach ($tablas as $tabla): ?>
                    <option value="<?= $tabla ?>" <?= $tablaSel === $tabla ? 'selected' : '' ?>><?= ucfirst($tabla) ?></option>
                <?php endforeach; ?>
            </select>
        </div>

        <div class="form-group">
            <label for="where_campo">Campo para filtrar (WHERE):</label>
            <input type="text" name="where_campo" id="where_campo" value="<?= htmlspecialchars($whereCampo) ?>" placeholder="(Opcional)">
        </div>

        <div class="form-group">
            <label for="where_valor">Valor:</label>
            <input type="text" name="where_valor" id="where_valor" value="<?= htmlspecialchars($whereValor) ?>" placeholder="(Opcional)">
        </div>

        <button type="submit">Ejecutar</button>
        <p><a href="main.php">Volver al inicio</a></p>
    </form>

    <?php if ($error): ?>
        <p class="error"><?= htmlspecialchars($error) ?></p>
    <?php endif; ?>

    <?php if (!empty($resultados)): ?>
        <h2>Resultados</h2>
        <table class="tabla-estandar">
            <thead>
                <tr>
                    <?php foreach (array_keys($resultados[0]) as $col): ?>
                        <th><?= htmlspecialchars($col) ?></th>
                    <?php endforeach; ?>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($resultados as $fila): ?>
                    <tr>
                        <?php foreach ($fila as $valor): ?>
                            <td><?= htmlspecialchars($valor) ?></td>
                        <?php endforeach; ?>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</div>
</body>
</html>