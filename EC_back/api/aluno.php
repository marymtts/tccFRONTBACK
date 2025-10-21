<?php
// Documentação: Este ficheiro contém todos os endpoints para a tabela 'alunos'.
// Ele lida com os pedidos HTTP (GET, POST, PUT, DELETE) e interage com o banco de dados.

// Cabeçalhos obrigatórios para a API.
// O '*' permite que qualquer origem (domínio) aceda a esta API. Por segurança, em produção,
// podes restringir isto a domínios específicos, como 'http://meu-site-react.com'.
header("Access-Control-Allow-Origin: *");
// Define que o conteúdo retornado será no formato JSON.
header("Content-Type: application/json; charset=UTF-8");
// Permite os métodos HTTP que a API irá aceitar.
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
// Define os cabeçalhos que são permitidos nos pedidos.
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclui o ficheiro de conexão com o banco de dados.
include_once '../config/database.php';

// Cria uma instância da classe Database para obter a conexão.
$database = new Database();
$db = $database->getConnection();

// Obtém o método HTTP do pedido (ex: "GET", "POST", etc.).
$method = $_SERVER['REQUEST_METHOD'];

// Estrutura de controlo para lidar com os diferentes métodos HTTP.
switch ($method) {
    // --- CASO GET: Buscar dados de alunos ---
    case 'GET':
        // Verifica se um 'id' foi passado na URL (ex: /api/alunos.php?id=123).
        if (isset($_GET['id'])) {
            $id = intval($_GET['id']);
            $stmt = $db->prepare("SELECT id, ra, nome, email FROM alunos WHERE id = :id");
            // Usar bindParam previne injeção de SQL.
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            $aluno = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($aluno) {
                http_response_code(200); // OK
                echo json_encode($aluno);
            } else {
                http_response_code(404); // Not Found
                echo json_encode(array("message" => "Aluno não encontrado."));
            }
        } else {
            // Se nenhum 'id' foi passado, retorna todos os alunos.
            // NOTA: Nunca seleciones a coluna 'senha' para retornar numa API pública!
            $stmt = $db->prepare("SELECT id, ra, nome, email FROM alunos");
            $stmt->execute();
            $alunos = $stmt->fetchAll(PDO::FETCH_ASSOC);

            http_response_code(200); // OK
            echo json_encode($alunos);
        }
        break;

    // --- CASO POST: Inserir um novo aluno ---
    case 'POST':
        // Obtém os dados enviados no corpo do pedido (em formato JSON).
        $data = json_decode(file_get_contents("php://input"));

        // Verifica se os dados necessários foram enviados.
        if (!empty($data->ra) && !empty($data->nome) && !empty($data->email) && !empty($data->senha)) {
            $query = "INSERT INTO alunos (ra, nome, email, senha) VALUES (:ra, :nome, :email, :senha)";
            $stmt = $db->prepare($query);

            // Limpa os dados para evitar problemas de segurança.
            $ra = htmlspecialchars(strip_tags($data->ra));
            $nome = htmlspecialchars(strip_tags($data->nome));
            $email = htmlspecialchars(strip_tags($data->email));
            // Hashing da senha - PRÁTICA DE SEGURANÇA FUNDAMENTAL!
            $senha_hashed = password_hash($data->senha, PASSWORD_BCRYPT);

            // Associa os valores às variáveis da query.
            $stmt->bindParam(':ra', $ra);
            $stmt->bindParam(':nome', $nome);
            $stmt->bindParam(':email', $email);
            $stmt->bindParam(':senha', $senha_hashed);

            if ($stmt->execute()) {
                http_response_code(201); // Created
                echo json_encode(array("message" => "Aluno criado com sucesso."));
            } else {
                http_response_code(503); // Service Unavailable
                echo json_encode(array("message" => "Não foi possível criar o aluno."));
            }
        } else {
            http_response_code(400); // Bad Request
            echo json_encode(array("message" => "Dados incompletos."));
        }
        break;

    // --- CASO PUT: Atualizar um aluno existente ---
    case 'PUT':
        // Obtém os dados do corpo do pedido e o ID da URL.
        $data = json_decode(file_get_contents("php://input"));
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        // Verifica se o ID e os dados necessários foram fornecidos.
        if ($id && !empty($data->ra) && !empty($data->nome) && !empty($data->email)) {
            $query = "UPDATE alunos SET ra = :ra, nome = :nome, email = :email";
            
            // Se uma nova senha for fornecida, atualiza também a senha.
            if (!empty($data->senha)) {
                $query .= ", senha = :senha";
            }
            
            $query .= " WHERE id = :id";

            $stmt = $db->prepare($query);

            // Limpa os dados.
            $ra = htmlspecialchars(strip_tags($data->ra));
            $nome = htmlspecialchars(strip_tags($data->nome));
            $email = htmlspecialchars(strip_tags($data->email));

            // Associa os valores.
            $stmt->bindParam(':ra', $ra);
            $stmt->bindParam(':nome', $nome);
            $stmt->bindParam(':email', $email);
            $stmt->bindParam(':id', $id);

            // Associa a senha apenas se foi fornecida.
            if (!empty($data->senha)) {
                $senha_hashed = password_hash($data->senha, PASSWORD_BCRYPT);
                $stmt->bindParam(':senha', $senha_hashed);
            }

            if ($stmt->execute()) {
                http_response_code(200); // OK
                echo json_encode(array("message" => "Aluno atualizado com sucesso."));
            } else {
                http_response_code(503); // Service Unavailable
                echo json_encode(array("message" => "Não foi possível atualizar o aluno."));
            }
        } else {
            http_response_code(400); // Bad Request
            echo json_encode(array("message" => "Dados incompletos ou ID não fornecido."));
        }
        break;

    // --- CASO DELETE: Excluir um aluno ---
    case 'DELETE':
        // Obtém o ID da URL.
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if ($id) {
            $query = "DELETE FROM alunos WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':id', $id);

            if ($stmt->execute()) {
                http_response_code(200); // OK
                echo json_encode(array("message" => "Aluno excluído com sucesso."));
            } else {
                http_response_code(503); // Service Unavailable
                echo json_encode(array("message" => "Não foi possível excluir o aluno."));
            }
        } else {
            http_response_code(400); // Bad Request
            echo json_encode(array("message" => "ID não fornecido."));
        }
        break;

    // --- CASO O MÉTODO NÃO SEJA SUPORTADO ---
    default:
        http_response_code(405); // Method Not Allowed
        echo json_encode(array("message" => "Método não permitido."));
        break;
}
?>