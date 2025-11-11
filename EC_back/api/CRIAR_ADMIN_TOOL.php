<?php
// Este é um script de ferramenta, SÓ PARA VOCÊ USAR.
// NÃO chame este arquivo pelo Flutter.
// Acesse-o diretamente no seu navegador.

// Inclui a conexão com o banco
include_once '../config/database.php';

$mensagem = ""; // Para mostrar feedback

// Verifica se o formulário foi enviado (se o usuário clicou em "Criar Admin")
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    
    // Pega os dados do formulário HTML
    $nome = $_POST['nome'];
    $email = $_POST['email'];
    $senha = $_POST['senha'];

    if (!empty($nome) && !empty($email) && !empty($senha)) {
        
        $database = new Database();
        $db = $database->getConnection();

        // Verifica se o email já existe na tabela USUARIOS
        $check_query = "SELECT id FROM usuarios WHERE email = :email LIMIT 1";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bindParam(':email', $email);
        $check_stmt->execute();

        if ($check_stmt->rowCount() > 0) {
            $mensagem = "Erro: O email '$email' já existe na tabela 'usuarios'!";
        } else {
            // --- A CRIPTOGRAFIA QUE VOCÊ QUERIA ---
            $senha_hash = password_hash($senha, PASSWORD_BCRYPT);
            
            // Insere na tabela 'usuarios' (Admins)
            $query = "INSERT INTO usuarios (nome, email, senha) VALUES (:nome, :email, :senha)";
            $stmt = $db->prepare($query);

            $stmt->bindParam(':nome', $nome);
            $stmt->bindParam(':email', $email);
            $stmt->bindParam(':senha', $senha_hash); // Salva o hash

            if ($stmt->execute()) {
                $mensagem = "SUCESSO! Admin '$nome' criado na tabela 'usuarios'.";
            } else {
                $mensagem = "Erro ao inserir no banco de dados.";
            }
        }
    } else {
        $mensagem = "Erro: Todos os campos são obrigatórios.";
    }
}
?>

<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <title>Ferramenta de Criação de Admin</title>
    <style>
        body { font-family: sans-serif; background-color: #333; color: white; padding: 20px; }
        form { background-color: #555; padding: 20px; border-radius: 8px; }
        input { width: 300px; padding: 8px; margin-bottom: 10px; }
        button { padding: 10px 20px; }
        .mensagem { font-size: 20px; font-weight: bold; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Ferramenta de Criação de Admin</h1>
    <p>Use este formulário para adicionar novos admins (ex: professores) na tabela 'usuarios'.</p>
    
    <?php if (!empty($mensagem)): ?>
        <p class="mensagem"><?php echo $mensagem; ?></p>
    <?php endif; ?>

    <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>" method="post">
        <label for="nome">Nome:</label><br>
        <input type="text" id="nome" name="nome" required><br>
        
        <label for="email">Email:</label><br>
        <input type="email" id="email" name="email" required><br>
        
        <label for="senha">Senha:</label><br>
        <input type="password" id="senha" name="senha" required><br><br>
        
        <button type="submit">Criar Admin</button>
    </form>
</body>
</html>