<?php
require_once '../vendor/autoload.php';
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

// --- CABEÇALHOS OBRIGATÓRIOS ---
// Permite que qualquer origem (seu app Flutter) acesse
header("Access-Control-Allow-Origin: *");
// Define o tipo de conteúdo que a API VAI RETORNAR
header("Content-Type: application/json; charset=UTF-8");
// Define QUAIS MÉTODOS o navegador pode usar
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
// Define QUAIS CABEÇALHOS o navegador pode enviar (CRUCIAL!)
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- CORREÇÃO DE CORS (PRE-FLIGHT) ---
// Verifica se o navegador está fazendo a "pergunta" OPTIONS
$method = $_SERVER['REQUEST_METHOD'];
if ($method == "OPTIONS") {

    http_response_code(200);
    exit();
}
// --- FIM DA CORREÇÃO ---
// Inclui a conexão com o banco
include_once '../config/database.php';

// Instancia o objeto de banco de dados
$database = new Database();
$db = $database->getConnection();
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
        // Pega os dados de texto (titulo, data, etc.) enviados como JSON
        // IMPORTANTE: Para enviar IMAGEM + DADOS, o Flutter usará multipart/form-data.
        // PHP não popula file_get_contents com multipart. Os dados de texto virão via $_POST.
        // $data = json_decode(file_get_contents("php://input")); // <<-- Comente ou remova esta linha

        // Em vez disso, pegamos os dados de texto do $_POST
        $titulo = isset($_POST['titulo']) ? $_POST['titulo'] : null;
        $descricao = isset($_POST['descricao']) ? $_POST['descricao'] : null;
        $data_evento = isset($_POST['data_evento']) ? $_POST['data_evento'] : null;
        $inscricao = isset($_POST['inscricao']) ? $_POST['inscricao'] : null; // Flutter enviará 'true'/'false' ou 1/0 como string


        // --- LÓGICA DA IMAGEM ---
        $imagem_url_para_db = null; // Caminho a ser salvo no banco (NULL por padrão)

        // Verifica se um arquivo foi enviado com o nome 'imagem_evento'
        if (isset($_FILES['imagem_evento']) && $_FILES['imagem_evento']['error'] == UPLOAD_ERR_OK) {
            
            $uploadDir = '../uploads/eventos/'; // Pasta de uploads
            $nomeArquivoOriginal = basename($_FILES['imagem_evento']['name']);
            $extensao = strtolower(pathinfo($nomeArquivoOriginal, PATHINFO_EXTENSION));
            $nomeArquivoUnico = uniqid('evento_', true) . '.' . $extensao; 
            $caminhoDestino = $uploadDir . $nomeArquivoUnico;

            $tiposPermitidos = ['jpg', 'jpeg', 'png', 'gif'];
            if (in_array($extensao, $tiposPermitidos)) {
                if (move_uploaded_file($_FILES['imagem_evento']['tmp_name'], $caminhoDestino)) {
                    // Guarda o caminho RELATIVO para o banco
                    $imagem_url_para_db = '/uploads/eventos/' . $nomeArquivoUnico; 
                } else {
                    http_response_code(500); 
                    echo json_encode(array("message" => "Erro ao salvar a imagem no servidor. Verifique permissões da pasta '$uploadDir'."));
                    exit(); 
                }
            } else {
                 http_response_code(400); 
                 echo json_encode(array("message" => "Tipo de imagem não permitido ($extensao). Use JPG, JPEG, PNG ou GIF."));
                 exit(); 
            }
        } elseif (isset($_FILES['imagem_evento']) && $_FILES['imagem_evento']['error'] != UPLOAD_ERR_NO_FILE) {
            // Se houve um erro no upload (diferente de "nenhum arquivo enviado")
             http_response_code(500); 
             echo json_encode(array("message" => "Erro durante o upload da imagem: código " . $_FILES['imagem_evento']['error']));
             exit(); 
        }
        // Se nenhum arquivo foi enviado (UPLOAD_ERR_NO_FILE), $imagem_url_para_db continua null, o que está correto.
        // --- FIM DA LÓGICA DA IMAGEM ---


        // Verifica se os dados de TEXTO (agora do $_POST) são válidos
        // Note que `inscricao` vem como string '1' ou '0', ou 'true'/'false'
        if (!empty($titulo) && !empty($data_evento) && isset($inscricao)) {
            
            // Query INSERT com a nova coluna imagem_url
            $query = "INSERT INTO eventos (titulo, descricao, data_evento, inscricao, imagem_url) VALUES (:titulo, :descricao, :data_evento, :inscricao, :imagem_url)";
            $stmt = $db->prepare($query);

            // Limpa os dados de texto
            $titulo_limpo = htmlspecialchars(strip_tags($titulo));
            $descricao_limpa = isset($descricao) ? htmlspecialchars(strip_tags($descricao)) : null;
            $data_evento_limpo = htmlspecialchars(strip_tags($data_evento));
            // Converte 'true'/'1' para 1, 'false'/'0'/outros para 0
            $inscricao_limpa = (strtolower($inscricao) === 'true' || $inscricao === '1') ? 1 : 0; 

            // Associa os valores
            $stmt->bindParam(':titulo', $titulo_limpo);
            $stmt->bindParam(':descricao', $descricao_limpa);
            $stmt->bindParam(':data_evento', $data_evento_limpo);
            $stmt->bindParam(':inscricao', $inscricao_limpa);
            $stmt->bindParam(':imagem_url', $imagem_url_para_db); // Associa o caminho da imagem (ou null)

            if ($stmt->execute()) {
                http_response_code(201); // Created
                echo json_encode(array("message" => "Evento criado com sucesso."));
            } else {
                // Tenta pegar mais detalhes do erro do PDO
                $errorInfo = $stmt->errorInfo();
                http_response_code(503); // Service Unavailable
                echo json_encode(array("message" => "Não foi possível criar o evento no banco.", "error_details" => $errorInfo[2]));
            }
        } else {
            http_response_code(400); // Bad Request
            echo json_encode(array("message" => "Dados incompletos recebidos via POST. 'titulo', 'data_evento' e 'inscricao' são obrigatórios."));
        }
        break;

    // --- CASO PUT: Atualizar um evento ---
    // --- CASO PUT: Atualizar um evento ---
    case 'PUT':
        // Como explicado antes, PUT com multipart é complexo.
        // Assumimos que o Flutter enviará como POST com os dados em $_POST e $_FILES.
        
        $id = isset($_GET['id']) ? intval($_GET['id']) : null; // ID vem da URL
        
        // Pega dados de texto do $_POST
        $titulo = isset($_POST['titulo']) ? $_POST['titulo'] : null;
        $descricao = isset($_POST['descricao']) ? $_POST['descricao'] : null;
        $data_evento = isset($_POST['data_evento']) ? $_POST['data_evento'] : null;
        $inscricao = isset($_POST['inscricao']) ? $_POST['inscricao'] : null; // Vem como string '1'/'0', etc.

        if (!$id) {
             http_response_code(400);
             echo json_encode(array("message" => "ID do evento não fornecido na URL para atualização."));
             break; 
        }

        // --- LÓGICA DA IMAGEM (similar ao POST, mas com opção de remover) ---
        $imagem_url_para_db = null; 
        $atualizar_imagem_url = false; 

        if (isset($_FILES['imagem_evento']) && $_FILES['imagem_evento']['error'] == UPLOAD_ERR_OK) {
            // ... (COPIE A LÓGICA DE UPLOAD DO 'case POST' AQUI) ...
            // Verifique $extensao, $tiposPermitidos
            // Tente move_uploaded_file(...)
            if (move_uploaded_file($_FILES['imagem_evento']['tmp_name'], $caminhoDestino)) {
                 $imagem_url_para_db = '/uploads/eventos/' . $nomeArquivoUnico;
                 $atualizar_imagem_url = true; 
                 // TODO: Opcional - Deletar a imagem antiga do servidor se existir
            } else {
                 http_response_code(500);
                 echo json_encode(array("message" => "Erro ao salvar a nova imagem no PUT."));
                 exit();
            }
        } elseif (isset($_POST['remover_imagem']) && ($_POST['remover_imagem'] == '1' || strtolower($_POST['remover_imagem']) == 'true')) {
             // Se o front-end mandou uma flag para remover a imagem
             $imagem_url_para_db = null; // Define como NULL
             $atualizar_imagem_url = true; // Marca para atualizar no DB
             // TODO: Opcional - Deletar o arquivo antigo do servidor aqui
        }
        // Se nenhuma imagem nova foi enviada e 'remover_imagem' não foi setado,
        // a imagem antiga no banco NÃO será alterada.
        // --- FIM DA LÓGICA DA IMAGEM ---


        // Verifica dados obrigatórios de texto
        if (!empty($titulo) && !empty($data_evento) && isset($inscricao)) {
            
            // Monta a query dinamicamente
            $query = "UPDATE eventos SET titulo = :titulo, descricao = :descricao, data_evento = :data_evento, inscricao = :inscricao";
            if ($atualizar_imagem_url) {
                $query .= ", imagem_url = :imagem_url"; // Só atualiza imagem se necessário
            }
            $query .= " WHERE id = :id";
            
            $stmt = $db->prepare($query);

            // Limpa dados de texto
            $titulo_limpo = htmlspecialchars(strip_tags($titulo));
            $descricao_limpa = isset($descricao) ? htmlspecialchars(strip_tags($descricao)) : null;
            $data_evento_limpo = htmlspecialchars(strip_tags($data_evento));
            $inscricao_limpa = (strtolower($inscricao) === 'true' || $inscricao === '1') ? 1 : 0;

            // Associa valores
            $stmt->bindParam(':titulo', $titulo_limpo);
            $stmt->bindParam(':descricao', $descricao_limpa);
            $stmt->bindParam(':data_evento', $data_evento_limpo);
            $stmt->bindParam(':inscricao', $inscricao_limpa);
            $stmt->bindParam(':id', $id);
            
            // Associa a imagem SÓ SE for para atualizar
            if ($atualizar_imagem_url) {
                $stmt->bindParam(':imagem_url', $imagem_url_para_db);
            }

            if ($stmt->execute()) {
                http_response_code(200); // OK
                echo json_encode(array("message" => "Evento atualizado com sucesso."));
            } else {
                $errorInfo = $stmt->errorInfo();
                http_response_code(503); 
                echo json_encode(array("message" => "Não foi possível atualizar o evento.", "error_details" => $errorInfo[2]));
            }
        } else {
            http_response_code(400); // Bad Request
            echo json_encode(array("message" => "Dados incompletos recebidos via POST para atualização."));
        }
        break; 

    // --- CASO DELETE: Excluir um evento (PROTEGIDO) ---
    case 'DELETE':
        // --- INÍCIO DA VALIDAÇÃO DE ADMIN ---
        $authHeader = null;
        if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
        } elseif (isset($_SERVER['HTTP_X_AUTHORIZATION'])) { // Fallback
            $authHeader = $_SERVER['HTTP_X_AUTHORIZATION'];
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
            $secret_key = "2h7B!_J4CL4j*nFRwQupt_1zd~Z?QtX%LQ0yW4V#"; // Sua chave secreta
            $decoded = JWT::decode($token, new Key($secret_key, 'HS256'));
            
            // VERIFICA SE O CARGO É 'admin'
            if ($decoded->data->role !== 'admin') {
                http_response_code(403); // Forbidden
                echo json_encode(array("message" => "Acesso negado. Apenas administradores podem apagar eventos."));
                exit();
            }
        } catch (Exception $e) {
            http_response_code(401); // Unauthorized
            echo json_encode(array("message" => "Acesso negado. Token inválido ou expirado.", "error" => $e->getMessage()));
            exit();
        }
        // --- FIM DA VALIDAÇÃO DE ADMIN ---

        // Se chegou até aqui, o usuário é um admin. Prossiga com o delete.
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if ($id) {
            // TODO: Antes de apagar o evento, seria bom apagar a imagem
            // (se houver) da pasta /uploads/eventos/
            
            $query = "DELETE FROM eventos WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':id', $id);

            if ($stmt->execute()) {
                // Também é uma boa prática apagar as participações associadas
                $db->prepare("DELETE FROM participacao WHERE id_evento = :id")->execute([':id' => $id]);

                http_response_code(200); // OK
                echo json_encode(array("status" => "success", "message" => "Evento excluído com sucesso."));
            } else {
                http_response_code(503); // Service Unavailable
                echo json_encode(array("status" => "error", "message" => "Não foi possível excluir o evento."));
            }
        } else {
            http_response_code(400); // Bad Request
            echo json_encode(array("status" => "error", "message" => "ID não fornecido."));
        }
        break;

    default:
        http_response_code(405); // Method Not Allowed
        echo json_encode(array("message" => "Método não permitido."));
        break;
}
?>