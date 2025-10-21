import React from 'react';
import './SobreNos.css'; // Importa os nossos estilos personalizados

function SobreNos() {
    return (
        // Usamos um React.Fragment (<>) para agrupar as duas secções sem adicionar uma div extra
        <>
            {/* --- PRIMEIRA SECÇÃO: QUEM SOMOS? --- */}
            <section className="sobre-nos-section">
                <div className="container">
                    <div className="row align-items-center g-5">
                        {/* Coluna da Esquerda: Texto */}
                        <div className="col-lg-6">
                            <h2 className="mb-4">Quem somos?</h2>
                            <p>
                                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed non risus. Suspendisse lectus tortor, dignissim sit amet, adipiscing nec, ultricies sed, dolor. Cras elementum ultrices diam. Maecenas ligula massa, varius a, semper congue, euismod non, mi.
                            </p>
                            <p>
                                Proin porttitor, orci nec nonummy molestie, enim est eleifend mi, non fermentum diam nisl sit amet erat. Duis semper. Duis arcu massa, scelerisque vitae, consequat in, pretium a, enim. Pellentesque congue.
                            </p>
                        </div>

                        {/* Coluna da Direita: Caixa "Equipe" */}
                        <div className="col-lg-6">
                            <div className="placeholder-box">
                                Equipe Eventos Cotil
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* --- SEGUNDA SECÇÃO: CHAMADA PARA AÇÃO --- */}
            <section className="divulgue-section">
                <div className="container text-center">
                    <h2 className="mb-3">Tem um evento para divulgar?</h2>
                    <p>
                        É organizador de algum centro académico, atlética, ou está planeando algo incrível? Manda pra gente! Teremos o prazer de ajudar na divulgação.
                    </p>
                    <a href="#" className="btn btn-fale-conosco">Fale Conosco</a>
                </div>
            </section>
        </>
    );
}

export default SobreNos;