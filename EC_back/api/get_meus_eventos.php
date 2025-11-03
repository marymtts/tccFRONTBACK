<?php
// Cabeçalhos obrigatórios (com correção de CORS)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, OPTIONS"); // Só precisamos de GET
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclui a conexão com o banco
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

// --- Correção de CORS (Pre-flight OPTIONS) ---
$method = $_SERVER['REQUEST_METHOD'];
if ($method == "OPTIONS") {
    http_response_code(200);
    exit(); 
}
// --- Fim da Correção ---

// 1. Verifica se o ID do aluno foi enviado pela URL
if (isset($_GET['id_aluno'])) {
    
    $id_aluno = intval($_GET['id_aluno']);

    // 2. A Query Mágica (com JOIN)
    // "Selecione todas as colunas da tabela 'eventos' (e)
    //  ONDE existe uma correspondência na tabela 'participacao' (p)
    //  entre o 'id' do evento e o 'id_evento' da participação
    //  E ONDE o 'id_aluno' na participação for o que recebemos."
    $query = "SELECT 
                e.id, 
                e.titulo, 
                e.descricao, 
                e.data_evento, 
                e.inscricao,
                e.imagem_url
              FROM 
                eventos e
              INNER JOIN 
                participacao p ON e.id = p.id_evento
              WHERE 
                p.id_aluno = :id_aluno
              ORDER BY 
                e.data_evento ASC"; // Ordena pelos eventos mais próximos

    $stmt = $db->prepare($query);
    $stmt->bindParam(':id_aluno', $id_aluno);
    $stmt->execute();

    $num = $stmt->rowCount();

    // 3. Verifica se encontrou eventos
    if ($num > 0) {
        $eventos_array = array();
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            extract($row);
            // Adiciona cada evento ao array
            $evento_item = array(
                "id" => $id,
                "titulo" => $titulo,
                "descricao" => $descricao,
                "data_evento" => $data_evento,
                "inscricao" => $inscricao,
                "imagem_url" => $imagem_url
            );
            array_push($eventos_array, $evento_item);
        }
        
        http_response_code(200); // OK
        echo json_encode($eventos_array); // Envia a lista de eventos
    } else {
        http_response_code(404); // Not Found
        echo json_encode(array("message" => "Nenhum evento encontrado para este aluno."));
    }
} else {
    // 4. Se o ID do aluno não foi enviado na URL
    http_response_code(400); // Bad Request
    echo json_encode(array("message" => "ID do aluno não fornecido."));
}
?>