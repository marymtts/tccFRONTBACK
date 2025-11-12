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
        // ... dentro do case 'GET':
    if (isset($_GET['id'])) {
        $id = intval($_GET['id']);
        
        // --- 1. BUSCA O EVENTO (igual antes) ---
        $stmt = $db->prepare("SELECT * FROM eventos WHERE id = :id");
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $evento = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($evento) {
            // --- 2. NOVA LÓGICA: CONTA OS INSCRITOS ---
            $stmt_count = $db->prepare("SELECT COUNT(*) as inscritos_count FROM participacao WHERE id_evento = :id_evento");
            $stmt_count->bindParam(':id_evento', $id);
            $stmt_count->execute();
            
            // Pega o resultado da contagem (ex: 15)
            $count_result = $stmt_count->fetch(PDO::FETCH_ASSOC);
            $inscritos_count = $count_result ? $count_result['inscritos_count'] : 0;
            
            // --- 3. ADICIONA A CONTAGEM AO RESULTADO ---
            $evento['inscritos_count'] = $inscritos_count;

            // --- 3. (NOVO!) VERIFICA SE O USUÁRIO ATUAL ESTÁ INSCRITO ---
            $evento['usuario_esta_inscrito'] = false; // Começa como falso
            if (isset($_GET['user_id'])) {
                $id_aluno = intval($_GET['user_id']);
                
                $stmt_check_user = $db->prepare("SELECT 1 FROM participacao WHERE id_aluno = :id_aluno AND id_evento = :id_evento LIMIT 1");
                $stmt_check_user->bindParam(':id_aluno', $id_aluno);
                $stmt_check_user->bindParam(':id_evento', $id_evento);
                $stmt_check_user->execute();
                
                if ($stmt_check_user->rowCount() > 0) {
                    $evento['usuario_esta_inscrito'] = true; // Define como verdadeiro se encontrou
                }
            }
            
            // --- 4. ENVIA TUDO JUNTO ---
            http_response_code(200); // OK
            echo json_encode($evento); // Agora envia {"id": ..., "titulo": ..., "inscritos_count": 15}

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
    // ... (seu switch($method) continua) ...

    case 'POST': // <-- ESTE CASE AGORA FAZ AS DUAS COISAS: CRIAR E ATUALIZAR
        
        // --- A MÁGICA ESTÁ AQUI ---
        // Primeiro, verificamos se um ID foi passado na URL
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if ($id) {
            // #######################################################
            // ## SE TEM ID (id != null), NÓS ESTAMOS ATUALIZANDO ##
            // ## (Esta é a lógica que estava no seu case 'PUT') ##
            // #######################################################
            
            // Pega dados de texto do $_POST
            $titulo = isset($_POST['titulo']) ? $_POST['titulo'] : null;
            $descricao = isset($_POST['descricao']) ? $_POST['descricao'] : null;
            $data_evento = isset($_POST['data_evento']) ? $_POST['data_evento'] : null;
            $inscricao = isset($_POST['inscricao']) ? $_POST['inscricao'] : null; 
            $max_participantes = isset($_POST['max_participantes']) ? $_POST['max_participantes'] : null;

            // LÓGICA DA IMAGEM (com opção de remover)
            $imagem_url_para_db = null; 
            $atualizar_imagem_url = false; 

            if (isset($_FILES['imagem_evento']) && $_FILES['imagem_evento']['error'] == UPLOAD_ERR_OK) {
                // ... (Lógica de upload de imagem) ...
                $uploadDir = '../uploads/eventos/';
                $nomeArquivoOriginal = basename($_FILES['imagem_evento']['name']);
                $extensao = strtolower(pathinfo($nomeArquivoOriginal, PATHINFO_EXTENSION));
                $nomeArquivoUnico = uniqid('evento_', true) . '.' . $extensao;
                $caminhoDestino = $uploadDir . $nomeArquivoUnico;
                
                if (move_uploaded_file($_FILES['imagem_evento']['tmp_name'], $caminhoDestino)) {
                    $imagem_url_para_db = '/uploads/eventos/' . $nomeArquivoUnico;
                    $atualizar_imagem_url = true;
                } else {
                    http_response_code(500);
                    echo json_encode(array("message" => "Erro ao salvar a nova imagem no PUT."));
                    exit();
                }
            } elseif (isset($_POST['remover_imagem']) && (strtolower($_POST['remover_imagem']) == 'true' || $_POST['remover_imagem'] == '1')) {
                $imagem_url_para_db = null;
                $atualizar_imagem_url = true; 
            }

            // Verifica dados obrigatórios
            if (!empty($titulo) && !empty($data_evento) && isset($inscricao)) {
                
                // Monta a query UPDATE
                $query = "UPDATE eventos SET 
                            titulo = :titulo, 
                            descricao = :descricao, 
                            data_evento = :data_evento, 
                            inscricao = :inscricao, 
                            max_participantes = :max_participantes";
                
                if ($atualizar_imagem_url) {
                    $query .= ", imagem_url = :imagem_url";
                }
                $query .= " WHERE id = :id";
                
                $stmt = $db->prepare($query);

                // Limpa dados
                $titulo_limpo = htmlspecialchars(strip_tags($titulo));
                $descricao_limpa = isset($descricao) ? htmlspecialchars(strip_tags($descricao)) : null;
                $data_evento_limpo = htmlspecialchars(strip_tags($data_evento));
                $inscricao_limpa = (strtolower($inscricao) === 'true' || $inscricao === '1') ? 1 : 0;

                $max_participantes_limpo = null;
                if ($inscricao_limpa == 1 && !empty($max_participantes) && intval($max_participantes) > 0) {
                    $max_participantes_limpo = intval($max_participantes);
                }

                // Associa valores
                $stmt->bindParam(':titulo', $titulo_limpo);
                $stmt->bindParam(':descricao', $descricao_limpa);
                $stmt->bindParam(':data_evento', $data_evento_limpo);
                $stmt->bindParam(':inscricao', $inscricao_limpa);
                $stmt->bindParam(':id', $id);
                $stmt->bindParam(':max_participantes', $max_participantes_limpo);
                
                if ($atualizar_imagem_url) {
                    $stmt->bindParam(':imagem_url', $imagem_url_para_db);
                }

                if ($stmt->execute()) {
                    http_response_code(200); // OK
                    echo json_encode(array("message" => "Evento ATUALIZADO com sucesso."));
                } else {
                    $errorInfo = $stmt->errorInfo();
                    http_response_code(503); 
                    echo json_encode(array("message" => "Não foi possível atualizar o evento.", "error_details" => $errorInfo[2]));
                }
            } else {
                http_response_code(400); // Bad Request
                echo json_encode(array("message" => "Dados incompletos para atualização."));
            }

        } else {
            // #######################################################
            // ## SE NÃO TEM ID (id == null), NÓS ESTAMOS CRIANDO ##
            // ## (Esta é a lógica que JÁ ESTAVA no seu case 'POST') ##
            // #######################################################

            // Pega os dados de texto do $_POST
            $titulo = isset($_POST['titulo']) ? $_POST['titulo'] : null;
            $descricao = isset($_POST['descricao']) ? $_POST['descricao'] : null;
            $data_evento = isset($_POST['data_evento']) ? $_POST['data_evento'] : null;
            $inscricao = isset($_POST['inscricao']) ? $_POST['inscricao'] : null;
            $max_participantes = isset($_POST['max_participantes']) ? $_POST['max_participantes'] : null;

            // --- LÓGICA DA IMAGEM (Criar) ---
            $imagem_url_para_db = null;
            if (isset($_FILES['imagem_evento']) && $_FILES['imagem_evento']['error'] == UPLOAD_ERR_OK) {
                // ... (Sua lógica de upload) ...
                $uploadDir = '../uploads/eventos/';
                $nomeArquivoOriginal = basename($_FILES['imagem_evento']['name']);
                $extensao = strtolower(pathinfo($nomeArquivoOriginal, PATHINFO_EXTENSION));
                $nomeArquivoUnico = uniqid('evento_', true) . '.' . $extensao; 
                $caminhoDestino = $uploadDir . $nomeArquivoUnico;

                $tiposPermitidos = ['jpg', 'jpeg', 'png', 'gif'];
                if (in_array($extensao, $tiposPermitidos)) {
                    if (move_uploaded_file($_FILES['imagem_evento']['tmp_name'], $caminhoDestino)) {
                        $imagem_url_para_db = '/uploads/eventos/' . $nomeArquivoUnico; 
                    } else {
                        http_response_code(500); 
                        echo json_encode(array("message" => "Erro ao salvar a imagem no servidor."));
                        exit(); 
                    }
                } else {
                    http_response_code(400); 
                    echo json_encode(array("message" => "Tipo de imagem não permitido ($extensao)."));
                    exit(); 
                }
            } elseif (isset($_FILES['imagem_evento']) && $_FILES['imagem_evento']['error'] != UPLOAD_ERR_NO_FILE) {
                http_response_code(500); 
                echo json_encode(array("message" => "Erro durante o upload da imagem: código " . $_FILES['imagem_evento']['error']));
                exit(); 
            }

            // Verifica dados obrigatórios
            if (!empty($titulo) && !empty($data_evento) && isset($inscricao)) {
                
                // Monta a query INSERT
                $query = "INSERT INTO eventos (titulo, descricao, data_evento, inscricao, imagem_url, max_participantes) 
                          VALUES (:titulo, :descricao, :data_evento, :inscricao, :imagem_url, :max_participantes)";
                
                $stmt = $db->prepare($query);

                // Limpa os dados
                $titulo_limpo = htmlspecialchars(strip_tags($titulo));
                $descricao_limpa = isset($descricao) ? htmlspecialchars(strip_tags($descricao)) : null;
                $data_evento_limpo = htmlspecialchars(strip_tags($data_evento));
                $inscricao_limpa = (strtolower($inscricao) === 'true' || $inscricao === '1') ? 1 : 0; 
                
                $max_participantes_limpo = null;
                if ($inscricao_limpa == 1 && !empty($max_participantes) && intval($max_participantes) > 0) {
                    $max_participantes_limpo = intval($max_participantes);
                }

                // Associa os valores
                $stmt->bindParam(':titulo', $titulo_limpo);
                $stmt->bindParam(':descricao', $descricao_limpa);
                $stmt->bindParam(':data_evento', $data_evento_limpo);
                $stmt->bindParam(':inscricao', $inscricao_limpa);
                $stmt->bindParam(':imagem_url', $imagem_url_para_db);
                $stmt->bindParam(':max_participantes', $max_participantes_limpo);

                if ($stmt->execute()) {
                    http_response_code(201); // Created
                    echo json_encode(array("message" => "Evento CRIADO com sucesso."));
                } else {
                    $errorInfo = $stmt->errorInfo();
                    http_response_code(503); 
                    echo json_encode(array("message" => "Não foi possível criar o evento no banco.", "error_details" => $errorInfo[2]));
                }
            } else {
                http_response_code(400); // Bad Request
                echo json_encode(array("message" => "Dados incompletos recebidos via POST. 'titulo', 'data_evento' e 'inscricao' são obrigatórios."));
            }
        }
        break;

    case 'PUT':
        // --- ESVAZIE ESTE CASE ---
        // Nós não o usamos mais, pois o POST faz tudo.
        http_response_code(405); // Method Not Allowed
        echo json_encode(array("message" => "Método PUT não é suportado. Use POST com ?id=... para atualizar."));
        break;

    // ... (seu case 'DELETE' e 'default' continuam iguais) ...
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