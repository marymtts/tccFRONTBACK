<?php
// Imports do Composer e da biblioteca JWT
require_once '../vendor/autoload.php';
use Firebase\JWT\JWT;

// Cabeçalhos obrigatórios
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclui a conexão com o banco
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];
if ($method == "OPTIONS") {
    http_response_code(200);
    exit(); // Responda "OK" para a "pergunta" OPTIONS e saia
}

// Obtém os dados do POST (JSON)
$data = json_decode(file_get_contents("php://input"));

// Verifica se email e senha foram enviados
if (!empty($data->email) && !empty($data->senha)) {
    
    // Procura o utilizador pelo email
    $query = "SELECT id, ra, nome, email, senha FROM alunos WHERE email = :email LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $data->email);
    $stmt->execute();

    $num = $stmt->rowCount();

    if ($num > 0) {
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        extract($row); // Extrai as variáveis $id, $nome, $email, $senha

        // Verifica se a senha enviada corresponde à senha "hasheada" no banco
        if (password_verify($data->senha, $senha)) {
            
            // --- GERAÇÃO DO TOKEN JWT ---
            $secret_key = "2h7B!_J4CL4j*nFRwQupt_1zd~Z?QtX%LQ0yW4V#"; // Muda isto para algo seguro!
            $issuer_claim = "http://localhost"; // O emissor do token
            $audience_claim = "http://localhost"; // A audiência do token
            $issuedat_claim = time(); // Hora de emissão
            $notbefore_claim = $issuedat_claim; // Token válido a partir de agora
            $expire_claim = $issuedat_claim + 3600; // Token expira em 1 hora

            $token = array(
                "iss" => $issuer_claim,
                "aud" => $audience_claim,
                "iat" => $issuedat_claim,
                "nbf" => $notbefore_claim,
                "exp" => $expire_claim,
                "data" => array( // Dados que queremos guardar no token
                    "id" => $id,
                    "nome" => $nome,
                    "email" => $email
                )
            );

            http_response_code(200); // OK

            // Codifica o token e envia-o
            $jwt = JWT::encode($token, $secret_key, 'HS256');
            echo json_encode(array("message" => "Login bem-sucedido.", "jwt" => $jwt));

        } else {
            http_response_code(401); // Unauthorized
            echo json_encode(array("message" => "Login falhou. Senha incorreta."));
        }
    } else {
        http_response_code(401); // Unauthorized
        echo json_encode(array("message" => "Login falhou. Utilizador não encontrado."));
    }
} else {
    http_response_code(400); // Bad Request
    echo json_encode(array("message" => "Dados incompletos."));
}
?>