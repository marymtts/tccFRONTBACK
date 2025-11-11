<?php
// Imports do Composer e da biblioteca JWT
require_once '../vendor/autoload.php';
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

// --- CABEÇALHOS OBRIGATÓRIOS ---
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS'); // Só GET é necessário
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// --- CORREÇÃO DE CORS (PRE-FLIGHT) ---
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

// --- 1. CONEXÃO COM O BANCO ---
include_once '../config/database.php';
$database = new Database();
$db = $database->getConnection();

// --- 2. VALIDAÇÃO DO TOKEN DE ADMIN ---
// (Bloco copiado do validar_checkin.php)
$authHeader = null;
if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
} else {
    http_response_code(401); 
    echo json_encode(array("message" => "Acesso negado. Token de autorização não fornecido."));
    exit();
}
$token = null;
if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
}
if (!$token) {
    http_response_code(401);
    echo json_encode(array("message" => "Acesso negado. Token mal formatado."));
    exit();
}
try {
    $secret_key = "2h7B!_J4CL4j*nFRwQupt_1zd~Z?QtX%LQ0yW4V#"; // Sua chave
    $decoded = JWT::decode($token, new Key($secret_key, 'HS256'));
    if ($decoded->data->role !== 'admin') {
        http_response_code(403); 
        echo json_encode(array("message" => "Acesso negado. Apenas administradores."));
        exit();
    }
} catch (Exception $e) {
    http_response_code(401);
    echo json_encode(array("message" => "Acesso negado. Token inválido ou expirado.", "error" => $e->getMessage()));
    exit();
}
// --- FIM DA VALIDAÇÃO DE ADMIN ---

// --- 3. LÓGICA DA API ---

// Pega o ID do evento da URL (ex: ...?id_evento=5)
$id_evento = isset($_GET['id_evento']) ? intval($_GET['id_evento']) : null;

if (empty($id_evento)) {
    http_response_code(400); // Bad Request
    echo json_encode(['message' => 'ID do evento não fornecido.']);
    exit;
}

try {
    // A QUERY MÁGICA (JOIN)
    // Seleciona os dados do aluno (a) e o status de check_in (p)
    // Juntando 'alunos' e 'participacao'
    // Onde o 'id_evento' for o que queremos
    $query = "SELECT 
                a.id, 
                a.nome, 
                a.ra, 
                a.email, 
                p.check_in 
              FROM 
                alunos a
              INNER JOIN 
                participacao p ON a.id = p.id_aluno
              WHERE 
                p.id_evento = ?
              ORDER BY 
                a.nome ASC"; // Ordena por nome

    $stmt = $db->prepare($query);
    $stmt->execute([$id_evento]);
    
    $inscritos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if ($inscritos) {
        http_response_code(200); // OK
        echo json_encode($inscritos);
    } else {
        // Não é um erro, apenas não há inscritos
        http_response_code(200); // OK
        echo json_encode([]); // Retorna uma lista vazia
    }

} catch (PDOException $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode(['message' => 'Erro no servidor (PDO): ' . $e->getMessage()]);
}

?>