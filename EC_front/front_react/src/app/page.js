import './page.css';
import { AiOutlineInstagram } from "react-icons/ai";
import { FiMessageSquare } from "react-icons/fi";

export default function Home() {
  return (
    <div className="parent">
      <div className="conteudo">
        <h1>
        Página inicial
        </h1>
        <br/>
        <h2>
          O Calendário Interativo do projeto Eventos Cotil foi pensado e desenvolvido para reformular a forma de pensar e se organizar na vida estudantil dentro do colégio.
        </h2>
      </div>
      <div className='conteudo2'>
        <a href="https://www.instagram.com/pedriicas">
        <AiOutlineInstagram size={50}/>
        </a>
        <br />
        <a href='contact'>
          <FiMessageSquare size={50}/>
        </a>
      </div>
      <div className='conteudo3'>
      </div>
    </div>
  );
}
