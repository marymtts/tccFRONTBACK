<?php
// Imports do Composer e da biblioteca JWT
require_once '../vendor/autoload.php';
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

// --- CABEÇALHOS OBRIGATÓRIOS ---
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS'); // Apenas POST
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

// --- 1. CONEXÃO COM O BANCO ---
include_once '../config/database.php';
$database = new Database();
$db = $database->getConnection();

// --- 2. VALIDAÇÃO DO TOKEN ---
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
$user_id = null;
$user_role = null;

try {
    $decoded = JWT::decode($token, new Key($secret_key, 'HS256'));
    $user_id = $decoded->data->id; // Pega o ID do token
    $user_role = $decoded->data->role; // Pega a role (aluno/admin)
} catch (Exception $e) {
    http_response_code(401);
    echo json_encode(["message" => "Token inválido ou expirado.", "error" => $e->getMessage()]);
    exit();
}
// --- FIM DA VALIDAÇÃO DE TOKEN ---

// --- 3. PEGAR OS DADOS DO FLUTTER ---
$data = json_decode(file_get_contents("php://input"));

$nome = $data->nome ?? null;
$email = $data->email ?? null;
$senha_anterior = $data->senha_anterior ?? null;
$nova_senha = $data->nova_senha ?? null;

if (empty($nome) || empty($email)) {
    http_response_code(400);
    echo json_encode(["message" => "Nome e email são obrigatórios."]);
    exit;
}

// Determina qual tabela atualizar (alunos ou usuarios)
$tabela = ($user_role === 'admin') ? 'usuarios' : 'alunos';

// --- 4. LÓGICA DE ATUALIZAÇÃO ---

// Inicia a query
$query = "UPDATE $tabela SET nome = :nome, email = :email";
$params = [
    ':nome' => htmlspecialchars(strip_tags($nome)),
    ':email' => htmlspecialchars(strip_tags($email)),
    ':id' => $user_id
];

$senha_foi_atualizada = false;

// Se o usuário quer atualizar a senha
if (!empty($nova_senha)) {
    // 1. Verifica se ele mandou a senha anterior
    if (empty($senha_anterior)) {
        http_response_code(400); // Bad Request
        echo json_encode(["message" => "Para definir uma nova senha, a senha anterior é obrigatória."]);
        exit;
    }

    // 2. Busca a senha atual no banco
    $stmt_check = $db->prepare("SELECT senha FROM $tabela WHERE id = :id");
    $stmt_check->execute([':id' => $user_id]);
    $user_row = $stmt_check->fetch(PDO::FETCH_ASSOC);

    if (!$user_row) {
        http_response_code(404);
        echo json_encode(["message" => "Usuário não encontrado."]);
        exit;
    }

    // 3. Verifica se a senha anterior bate com a do banco
    if (password_verify($senha_anterior, $user_row['senha'])) {
        // Sucesso! A senha anterior está correta.
        $novo_hash_senha = password_hash($nova_senha, PASSWORD_BCRYPT);
        
        // Adiciona a senha na query de atualização
        $query .= ", senha = :senha";
        $params[':senha'] = $novo_hash_senha;
        $senha_foi_atualizada = true;
    } else {
        // Falha! A senha anterior está errada.
        http_response_code(403); // Forbidden
        echo json_encode(["message" => "Senha anterior incorreta."]);
        exit;
    }
}

// 5. Executa a atualização final (Nome, Email e Senha se houver)
$query .= " WHERE id = :id";
$stmt_update = $db->prepare($query);

if ($stmt_update->execute($params)) {
    // Se a atualização deu certo, GERAMOS UM NOVO TOKEN
    // (porque o 'nome' ou 'email' no token antigo estão desatualizados)
    
    // Pega o RA (se for aluno) para o novo token
    $ra = ($user_role === 'aluno') ? $decoded->data->ra : null;

    $issuer_claim = "http://localhost"; 
    $audience_claim = "http://localhost";
    $issuedat_claim = time(); 
    $expire_claim = $issuedat_claim + 3600; // 1 hora

    $novo_token_data = array(
        "iss" => $issuer_claim, "aud" => $audience_claim, "iat" => $issuedat_claim, "exp" => $expire_claim,
        "data" => array(
            "id" => $user_id,
            "nome" => $nome, // <-- Novo nome
            "email" => $email, // <-- Novo email
            "ra" => $ra,
            "role" => $user_role
        )
    );
    
    $jwt = JWT::encode($novo_token_data, $secret_key, 'HS256');

    http_response_code(200);
    echo json_encode([
        "message" => "Perfil atualizado com sucesso.",
        "novo_jwt" => $jwt // Envia o novo token para o app
    ]);

} else {
    http_response_code(503);
    echo json_encode(["message" => "Não foi possível atualizar o perfil."]);
}
?>