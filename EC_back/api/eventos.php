<?php
// Documentação: Endpoints para a gestão de eventos.

// Cabeçalhos obrigatórios para a API
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclui a conexão com o banco de dados
include_once '../config/database.php';

// Instancia o objeto de banco de dados
$database = new Database();
$db = $database->getConnection();

// Obtém o método da requisição
$method = $_SERVER['REQUEST_METHOD'];

// Lógica para cada método HTTP
switch ($method) {
    // --- CASO GET: Buscar eventos ---
    case 'GET':
        if (isset($_GET['id'])) {
            $id = intval($_GET['id']);
            $stmt = $db->prepare("SELECT * FROM eventos WHERE id = :id");
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            $evento = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($evento) {
                http_response_code(200); // OK
                echo json_encode($evento);
            } else {
                http_response_code(404); // Not Found
                echo json_encode(array("message" => "Evento não encontrado."));
            }
        } else {
            // Retorna todos os eventos, ordenados pela data mais recente primeiro
            $stmt = $db->prepare("SELECT * FROM eventos ORDER BY data_evento DESC");
            $stmt->execute();
            $eventos = $stmt->fetchAll(PDO::FETCH_ASSOC);

            http_response_code(200); // OK
            echo json_encode($eventos);
        }
        break;

    // --- CASO POST: Inserir um novo evento ---
    case 'POST':
        $data = json_decode(file_get_contents("php://input"));

        // A descrição é opcional, mas os outros campos são obrigatórios.
        if (!empty($data->titulo) && !empty($data->data_evento) && isset($data->inscricao)) {
            $query = "INSERT INTO eventos (titulo, descricao, data_evento, inscricao) VALUES (:titulo, :descricao, :data_evento, :inscricao)";
            $stmt = $db->prepare($query);

            // Limpa os dados
            $titulo = htmlspecialchars(strip_tags($data->titulo));
            $descricao = isset($data->descricao) ? htmlspecialchars(strip_tags($data->descricao)) : null;
            $data_evento = htmlspecialchars(strip_tags($data->data_evento));
            // Converte para booleano e depois para inteiro (0 ou 1)
            $inscricao = boolval($data->inscricao) ? 1 : 0; 

            // Associa os valores
            $stmt->bindParam(':titulo', $titulo);
            $stmt->bindParam(':descricao', $descricao);
            $stmt->bindParam(':data_evento', $data_evento);
            $stmt->bindParam(':inscricao', $inscricao);

            if ($stmt->execute()) {
                http_response_code(201); // Created
                echo json_encode(array("message" => "Evento criado com sucesso."));
            } else {
                http_response_code(503); // Service Unavailable
                echo json_encode(array("message" => "Não foi possível criar o evento."));
            }
        } else {
            http_response_code(400); // Bad Request
            echo json_encode(array("message" => "Dados incompletos. 'titulo', 'data_evento' e 'inscricao' são obrigatórios."));
        }
        break;

    // --- CASO PUT: Atualizar um evento ---
    case 'PUT':
        $data = json_decode(file_get_contents("php://input"));
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if ($id && !empty($data->titulo) && !empty($data->data_evento) && isset($data->inscricao)) {
            $query = "UPDATE eventos SET titulo = :titulo, descricao = :descricao, data_evento = :data_evento, inscricao = :inscricao WHERE id = :id";
            $stmt = $db->prepare($query);

            // Limpa os dados
            $titulo = htmlspecialchars(strip_tags($data->titulo));
            $descricao = isset($data->descricao) ? htmlspecialchars(strip_tags($data->descricao)) : null;
            $data_evento = htmlspecialchars(strip_tags($data->data_evento));
            $inscricao = boolval($data->inscricao) ? 1 : 0;

            // Associa os valores
            $stmt->bindParam(':titulo', $titulo);
            $stmt->bindParam(':descricao', $descricao);
            $stmt->bindParam(':data_evento', $data_evento);
            $stmt->bindParam(':inscricao', $inscricao);
            $stmt->bindParam(':id', $id);

            if ($stmt->execute()) {
                http_response_code(200); // OK
                echo json_encode(array("message" => "Evento atualizado com sucesso."));
            } else {
                http_response_code(503); // Service Unavailable
                echo json_encode(array("message" => "Não foi possível atualizar o evento."));
            }
        } else {
            http_response_code(400); // Bad Request
            echo json_encode(array("message" => "Dados incompletos ou ID não fornecido."));
        }
        break;

    // --- CASO DELETE: Excluir um evento ---
    case 'DELETE':
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if ($id) {
            $query = "DELETE FROM eventos WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':id', $id);

            if ($stmt->execute()) {
                http_response_code(200); // OK
                echo json_encode(array("message" => "Evento excluído com sucesso."));
            } else {
                http_response_code(503); // Service Unavailable
                echo json_encode(array("message" => "Não foi possível excluir o evento."));
            }
        } else {
            http_response_code(400); // Bad Request
            echo json_encode(array("message" => "ID não fornecido."));
        }
        break;

    default:
        http_response_code(405); // Method Not Allowed
        echo json_encode(array("message" => "Método não permitido."));
        break;
}
?>