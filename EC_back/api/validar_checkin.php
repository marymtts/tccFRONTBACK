<?php
// Imports do Composer e da biblioteca JWT (copiado do seu eventos.php)
require_once '../vendor/autoload.php';
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

// --- CABEÇALHOS OBRIGATÓRIOS ---
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// --- CORREÇÃO DE CORS (PRE-FLIGHT) ---
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

// --- CORREÇÃO 1: CONEXÃO COM O BANCO ---
// (Usando o seu arquivo e método exatos)
include_once '../config/database.php';
$database = new Database();
$db = $database->getConnection(); // <-- Sua variável de conexão é $db

// --- CORREÇÃO 2: VALIDAÇÃO DO TOKEN DE ADMIN ---
// (Este bloco foi copiado do seu 'eventos.php' no case 'DELETE')

$authHeader = null;
if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
} else {
    http_response_code(401); // Unauthorized
    echo json_encode(array("message" => "Acesso negado. Token de autorização não fornecido."));
    exit();
}

$token = null;
if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
}

if (!$token) {
    http_response_code(401); // Unauthorized
    echo json_encode(array("message" => "Acesso negado. Token mal formatado."));
    exit();
}

try {
    // A SUA CHAVE SECRETA (copiada do seu login.php e eventos.php)
    $secret_key = "2h7B!_J4CL4j*nFRwQupt_1zd~Z?QtX%LQ0yW4V#"; 
    $decoded = JWT::decode($token, new Key($secret_key, 'HS256'));
    
    // VERIFICA SE O CARGO É 'admin'
    if ($decoded->data->role !== 'admin') {
        http_response_code(403); // Forbidden
        echo json_encode(array("message" => "Acesso negado. Apenas administradores podem validar o check-in."));
        exit();
    }
    // Se chegou aqui, o usuário é um admin.
} catch (Exception $e) {
    http_response_code(401); // Unauthorized
    echo json_encode(array("message" => "Acesso negado. Token inválido ou expirado.", "error" => $e->getMessage()));
    exit();
}
// --- FIM DA VALIDAÇÃO DE ADMIN ---

// --- 3. PEGAR OS DADOS ENVIADOS PELO FLUTTER ---
$data = json_decode(file_get_contents('php://input'), true);

$id_aluno = $data['id_aluno'] ?? null;
$id_evento = $data['id_evento'] ?? null;

if (empty($id_aluno) || empty($id_evento)) {
    http_response_code(400); // Bad Request
    echo json_encode(['message' => 'Dados incompletos. (id_aluno e id_evento são obrigatórios)']);
    exit;
}

// --- 4. LÓGICA DE CHECK-IN ---

try {
    // --- CORREÇÃO 3: USAR $db (em vez de $pdo) ---
    
    // Passo A: Verificar se o aluno está inscrito
    // (Usando o estilo de 'execute' com array, que você usa no eventos.php)
    $stmt = $db->prepare("SELECT * FROM participacao WHERE id_aluno = ? AND id_evento = ?");
    $stmt->execute([$id_aluno, $id_evento]);
    $participacao = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$participacao) {
        http_response_code(404); // Not Found
        echo json_encode(['message' => 'Erro: Aluno não inscrito neste evento.']);
        exit;
    }

    // Passo B: Verificar se o check-in JÁ foi feito
    if ($participacao['check_in'] != 0) { 
        http_response_code(409); // Conflict
        echo json_encode(['message' => 'Atenção: Check-in deste aluno JÁ foi realizado.']);
        exit;
    }

    // Passo C: VALIDAR O CHECK-IN (O Caminho Feliz)
    $updateStmt = $db->prepare("UPDATE participacao SET check_in = 1 WHERE id_aluno = ? AND id_evento = ?");
    
    if ($updateStmt->execute([$id_aluno, $id_evento])) {
        http_response_code(200); // OK
        echo json_encode(['message' => 'Check-in VALIDADO com sucesso!']);
    } else {
        throw new Exception("Não foi possível atualizar o registro.");
    }

} catch (PDOException $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode(['message' => 'Erro no servidor (PDO): ' . $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode(['message' => 'Erro no servidor: ' . $e->getMessage()]);
}

?>