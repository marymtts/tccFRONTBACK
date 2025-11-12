<?php
// Imports do Composer e da biblioteca JWT
require_once '../vendor/autoload.php';
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

// --- CABEÇALHOS OBRIGATÓRIOS ---
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS'); // Usaremos POST para enviar o ID do evento
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

// --- 1. CONEXÃO COM O BANCO ---
include_once '../config/database.php';
$database = new Database();
$db = $database->getConnection();

// --- 2. VALIDAÇÃO DO TOKEN (ESSENCIAL) ---
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? null;
if (!$authHeader) {
    http_response_code(401); 
    echo json_encode(["message" => "Token de autorização não fornecido."]);
    exit();
}
$token = null;
if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
}
if (!$token) {
    http_response_code(401);
    echo json_encode(["message" => "Token mal formatado."]);
    exit();
}

$secret_key = "2h7B!_J4CL4j*nFRwQupt_1zd~Z?QtX%LQ0yW4V#"; // Sua chave
$id_aluno = null;

try {
    $decoded = JWT::decode($token, new Key($secret_key, 'HS256'));
    $id_aluno = $decoded->data->id; // Pega o ID do aluno DIRETAMENTE DO TOKEN
} catch (Exception $e) {
    http_response_code(401);
    echo json_encode(["message" => "Token inválido ou expirado."]);
    exit();
}
// --- FIM DA VALIDAÇÃO DE TOKEN ---

// --- 3. PEGAR OS DADOS ENVIADOS PELO FLUTTER ---
$data = json_decode(file_get_contents("php://input"));
$id_evento = $data->id_evento ?? null;

if (empty($id_evento)) {
    http_response_code(400);
    echo json_encode(['message' => 'ID do evento não fornecido.']);
    exit;
}

// --- 4. LÓGICA DE EXCLUSÃO ---
try {
    $stmt = $db->prepare("DELETE FROM participacao WHERE id_aluno = :id_aluno AND id_evento = :id_evento");
    $stmt->bindParam(':id_aluno', $id_aluno);
    $stmt->bindParam(':id_evento', $id_evento);

    if ($stmt->execute()) {
        if ($stmt->rowCount() > 0) {
            http_response_code(200); // OK
            echo json_encode(['message' => 'Inscrição cancelada com sucesso.']);
        } else {
            http_response_code(404); // Not Found
            echo json_encode(['message' => 'Inscrição não encontrada.']);
        }
    } else {
        throw new Exception("Não foi possível executar a exclusão.");
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['message' => 'Erro no servidor: ' . $e->getMessage()]);
}

?>