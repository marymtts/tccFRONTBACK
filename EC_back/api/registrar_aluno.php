<?php
// Cabeçalhos obrigatórios da API
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS"); // Garante que POST é permitido
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclui a conexão com o banco
include_once '../config/database.php';

// Pega a conexão com o banco
$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

// Se o navegador estiver fazendo a "pergunta" OPTIONS...
if ($method == "OPTIONS") {
    // ...apenas responda "OK" e saia.
    http_response_code(200);
    exit(); // Para o script aqui. Não precisa fazer mais nada.
}

// Pega os dados enviados pelo Flutter (em formato JSON)
$data = json_decode(file_get_contents("php://input"));

// 1. Validação Simples: Verifica se os dados necessários vieram
if (
    !empty($data->ra) &&
    !empty($data->nome) &&
    !empty($data->email) &&
    !empty($data->senha)
) {
    // 2. Verificação de Duplicidade: O email ou RA já existem?
    $check_query = "SELECT id FROM alunos WHERE email = :email OR ra = :ra LIMIT 1";
    $check_stmt = $db->prepare($check_query);
    
    // Limpa os dados
    $email = htmlspecialchars(strip_tags($data->email));
    $ra = htmlspecialchars(strip_tags($data->ra));
    
    $check_stmt->bindParam(':email', $email);
    $check_stmt->bindParam(':ra', $ra);
    $check_stmt->execute();

    if ($check_stmt->rowCount() > 0) {
        // Se encontrou um registro, o email ou RA já existe
        http_response_code(409); // 409 Conflict (Conflito)
        echo json_encode(array("status" => "error", "message" => "Email ou RA já cadastrado."));
        exit(); // Para a execução
    }

    // 3. Se passou nas verificações, prepara para inserir
    $query = "INSERT INTO alunos (ra, nome, email, senha) VALUES (:ra, :nome, :email, :senha)";
    $stmt = $db->prepare($query);

    // Limpa os dados (o email e ra já foram limpos)
    $nome = htmlspecialchars(strip_tags($data->nome));

    // --- SEGURANÇA CRÍTICA ---
    // NUNCA salve a senha como texto puro. Use password_hash.
    $senha_hash = password_hash($data->senha, PASSWORD_BCRYPT);
    // --- FIM DA SEGURANÇA ---

    // Associa os valores aos parâmetros
    $stmt->bindParam(':ra', $ra);
    $stmt->bindParam(':nome', $nome);
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':senha', $senha_hash); // Salva o HASH, não a senha

    // 4. Executa a query
    if ($stmt->execute()) {
        http_response_code(201); // 201 Created
        echo json_encode(array("status" => "success", "message" => "Aluno registrado com sucesso."));
    } else {
        http_response_code(503); // 503 Service Unavailable
        echo json_encode(array("status" => "error", "message" => "Não foi possível registrar o aluno."));
    }
} else {
    // 5. Se os dados vieram incompletos
    http_response_code(400); // 400 Bad Request
    echo json_encode(array("status" => "error", "message" => "Dados incompletos. RA, nome, email e senha são obrigatórios."));
}
?>