<?php

// 1. Coloca aqui a senha em texto puro que estás a usar para fazer o login.
$senha_do_formulario = '12345'; 

// 2. Cola aqui o hash COMPLETO que copiaste do teu banco de dados.
$hash_do_banco_de_dados = '$2y$10$fCSuhz37i9zqsxv6TBpZOuwwoDzVziT/L5wPboHl.o.iUod0xbhNm'; 

// --- O SCRIPT DE VERIFICAÇÃO ---
echo "A testar a verificação da senha...<br><br>";
echo "Senha do formulário: " . htmlspecialchars($senha_do_formulario) . "<br>";
echo "Hash do banco de dados: " . htmlspecialchars($hash_do_banco_de_dados) . "<br><br>";

if (password_verify($senha_do_formulario, $hash_do_banco_de_dados)) {
    echo '<h2 style="color: green;">SUCESSO: A senha está CORRETA!</h2>';
} else {
    echo '<h2 style="color: red;">FALHA: A senha está INCORRETA!</h2>';
}

echo "<br>Comprimento do hash: " . strlen($hash_do_banco_de_dados);

?>