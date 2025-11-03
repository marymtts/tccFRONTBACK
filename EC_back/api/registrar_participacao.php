<?php
// Cabeçalhos obrigatórios da API (incluindo a correção de CORS)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS"); // Só precisamos de POST e OPTIONS
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclui a conexão com o banco
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

// --- Correção de CORS (Pre-flight OPTIONS) ---
$method = $_SERVER['REQUEST_METHOD'];
if ($method == "OPTIONS") {
    http_response_code(200);
    exit(); // Responda "OK" para a "pergunta" OPTIONS e saia
}
// --- Fim da Correção ---

// Pega os dados enviados pelo Flutter (em formato JSON)
$data = json_decode(file_get_contents("php://input"));

// 1. Validação Simples: Verifica se os IDs vieram
if (
    !empty($data->id_aluno) &&
    !empty($data->id_evento)
) {
    // 2. Verificação de Duplicidade: O aluno já está inscrito neste evento?
    $check_query = "SELECT id_aluno FROM participacao WHERE id_aluno = :id_aluno AND id_evento = :id_evento LIMIT 1";
    $check_stmt = $db->prepare($check_query);
    
    $id_aluno = intval($data->id_aluno);
    $id_evento = intval($data->id_evento);
    
    $check_stmt->bindParam(':id_aluno', $id_aluno);
    $check_stmt->bindParam(':id_evento', $id_evento);
    $check_stmt->execute();

    if ($check_stmt->rowCount() > 0) {
        // Se encontrou um registro, o aluno já está inscrito
        http_response_code(409); // 409 Conflict (Conflito)
        echo json_encode(array("status" => "error", "message" => "Você já está inscrito neste evento."));
        exit(); // Para a execução
    }

    // TODO: Adicionar lógica de "vagas esgotadas" que você mencionou
    // (Precisaria buscar 'max_participantes' da tabela 'eventos' e comparar com o COUNT da 'participacao')

    // 3. Se passou nas verificações, prepara para inserir
    $query = "INSERT INTO participacao (id_aluno, id_evento) VALUES (:id_aluno, :id_evento)";
    $stmt = $db->prepare($query);

    // Associa os valores aos parâmetros
    $stmt->bindParam(':id_aluno', $id_aluno);
    $stmt->bindParam(':id_evento', $id_evento);

    // 4. Executa a query
    if ($stmt->execute()) {
        http_response_code(201); // 201 Created
        echo json_encode(array("status" => "success", "message" => "Inscrição realizada com sucesso!"));
    } else {
        http_response_code(503); // 503 Service Unavailable
        echo json_encode(array("status" => "error", "message" => "Não foi possível registrar a participação."));
    }
} else {
    // 5. Se os dados vieram incompletos
    http_response_code(400); // 400 Bad Request
    echo json_encode(array("status" => "error", "message" => "Dados incompletos. 'id_aluno' e 'id_evento' são obrigatórios."));
}
?>