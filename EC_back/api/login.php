<?php
// Imports do Composer e da biblioteca JWT
require_once '../vendor/autoload.php';
use Firebase\JWT\JWT;

// Cabeçalhos obrigatórios (com correção de CORS para OPTIONS)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Max-Age: 3600");
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

// Obtém os dados do POST (JSON)
$data = json_decode(file_get_contents("php://input"));

// Verifica se email e senha foram enviados
if (empty($data->email) || empty($data->senha)) {
    http_response_code(400); // Bad Request
    echo json_encode(array("status" => "error", "message" => "Dados incompletos. Email e senha são obrigatórios."));
    exit();
}

// --- LÓGICA DE LOGIN COM ROLES (ADMIN PRIMEIRO) ---

// 1. Tenta encontrar um ADMIN (na tabela 'usuarios')
$query = "SELECT id, nome, email, senha FROM usuarios WHERE email = :email LIMIT 1";
$stmt = $db->prepare($query);
$stmt->bindParam(':email', $data->email);
$stmt->execute();

$user_data = null;
$user_role = null;

if ($stmt->rowCount() > 0) {
    // Encontrou na tabela 'usuarios', é um ADMIN
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (password_verify($data->senha, $row['senha'])) {
        $user_data = $row;
        $user_role = "admin";
        // Adiciona um campo 'ra' vazio para o token ficar igual ao do aluno
        $user_data['ra'] = null; 
    }
}

// 2. Se NÃO encontrou um admin válido, tenta encontrar um ALUNO (na tabela 'alunos')
if ($user_data === null) {
    $query = "SELECT id, ra, nome, email, senha FROM alunos WHERE email = :email LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $data->email);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        // Encontrou na tabela 'alunos', é um ALUNO
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (password_verify($data->senha, $row['senha'])) {
            $user_data = $row;
            $user_role = "aluno";
        }
    }
}

// 3. Verifica se o login foi bem-sucedido (encontrou um admin ou um aluno)
if ($user_data !== null && $user_role !== null) {
    
    // --- GERAÇÃO DO TOKEN JWT (COM A ROLE) ---
    $secret_key = "2h7B!_J4CL4j*nFRwQupt_1zd~Z?QtX%LQ0yW4V#"; // Você DEVE mudar isso!
    $issuer_claim = "http://https://tccfrontback.onrender.com"; 
    $audience_claim = "http://https://tccfrontback.onrender.com";
    $issuedat_claim = time(); 
    $notbefore_claim = $issuedat_claim; 
    $expire_claim = $issuedat_claim + 3600 * 8; // Expira em 8 horas

    $token = array(
        "iss" => $issuer_claim,
        "aud" => $audience_claim,
        "iat" => $issuedat_claim,
        "nbf" => $notbefore_claim,
        "exp" => $expire_claim,
        "data" => array( // Dados que queremos guardar no token
            "id" => $user_data['id'],
            "nome" => $user_data['nome'],
            "email" => $user_data['email'],
            "ra" => $user_data['ra'],      // Será 'null' para admins, o que está OK
            "role" => $user_role         // <-- A ROLE (cargo) está aqui!
        )
    );

    http_response_code(200); // OK

    // Codifica o token e envia-o
    $jwt = JWT::encode($token, $secret_key, 'HS256');
    echo json_encode(array(
        "status" => "success",
        "message" => "Login bem-sucedido.", 
        "jwt" => $jwt
    ));

} else {
    // Se $user_data ainda for nulo, a senha estava errada ou o usuário não existe
    http_response_code(401); // Unauthorized
    echo json_encode(array("status" => "error", "message" => "Login falhou. Email ou senha incorretos."));
}
?>