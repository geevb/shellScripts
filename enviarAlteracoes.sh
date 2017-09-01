#!/bin/bash
# Efetua Pull, Add, Commit e Push para o servidor
# Autor: Getúlio Benincá
# 30/09/2016
############################################# 

# Para que o script funcione corretamente é necessário setar variáveis 'user.name'  e 'user.email' no console da seguinte forma:
#git config --global user.email "email@servidor"
#git config --global user.name "nome usuario"

# Utilizar o default de Push configurado
git config --global push.default matching

# Localizar script e libs
readonly currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${currentDir}"/libs/libGeneric.sh
source "${currentDir}"/libs/libRun.sh

loopCommit=true
apagarLogs=false

# Criar pasta para os LOGS dos comandos do GIT
criarPastaLogs

# Limpar Pasta de LOGS
if [ -n $(ls "${currentDir}"/libs/logs/) ]; then
        rm -f "${currentDir}"/libs/logs/log*
else
        :
fi

# Retornar para a pasta Principal do Repositório
cd ../

# Desconsiderando as alterações realizadas em Recent Chances para previnir problemas de conflito.
echo -e "1) ${GREEN}Efetuando Checkout${NC}\n"
git checkout "FitNesseRoot/RecentChanges/content.txt"


# Adicionando alterações do Local Atual
echo -e "2) ${GREEN}Adicionando alteracoes${NC}\n"
git add -A 


# Criando log do comando GIT Status
git status >> "${currentDir}"/libs/logs/logStatus.log 2>&1 ; 


# Verificar o retorno do comando GIT Commit, caso retorne algo diferente de 0, entrará em estado de erro e finalizará o processo.
# Esperar Input do usuário para mensagem de Commit, validando a informação inserida, caso contrário retornando para que seja escrito novamente.
echo -e "3) ${GREEN}Commitando alteracoes${NC}"

while [ "$loopCommit" = true ]
do
read -e -p "Digite sua mensagem para commit: " mensagemCommit
echo -e "Voce digitou: ${mensagemCommit}\n"
read -e -p "Esta da maneira que queria? (S/N) " respostaCommit
case "${respostaCommit}" in 
	   y|Y|Yes|YEs|YES|s|S|Sim|SIm|SIM ) echo -e "${GREEN}Commit efetuado${NC}"; loopCommit=false; 
	   if [ ! git commit -v "${currentDir}/../" -m "${mensagemCommit} - ${dataAtual}" >> "${currentDir}"/libs/logs/logCommit.log 2>&1 ]; then 
			echo -e "${RED}Conflito de commit encontrado.${NC} \nLog do erro em: libs/logs/ - Por favor corrija-o manualmente e efetue o commit novamente.\n"
			echo -e "Pressione ENTER p/ finalizar."
			read
			exit
	   else
			:
	   fi ;;
	   n|N|no|No|nao|Nao|NAo|NAO|não|Não|NÃo|NÃO ) echo -e "Por favor, digite a mensagem novamente!\n";;
	   *) echo -e " ${RED}Resposta invalida${NC}, por favor digite sua mensagem e confirme novamente!\n";;
esac
done


# Criar arquivo de Log contendo as mensagens apresentadas pelo comando Git PULL
echo -e "\n4) ${GREEN}Efetuando Pull.${NC}"
echo -e "\n5) ${RED}Por favor, digite sua senha:${NC}"


# Verificar o retorno do comando GIT Pull, caso retorne algo diferente de 0, entrará em estado de erro e finalizará o processo.
# git pull -v >> logs/logPull.log 2>&1 
if [ ! git pull -v >> "${currentDir}"/libs/logs/logPull.log 2>&1 ]; then 
	echo -e " ${RED}Conflito de pull encontrado.${NC} \nLog do erro em: libs/logs/ - Por favor corrija-o manualmente e efetue o pull novamente."
	echo -e "Pressione ENTER p/ finalizar."
	read
	exit
else
	:
fi


# Criar arquivo de Log contendo as mensagem apresentadas pelo comando Git PUSH
echo -e "\n6) ${GREEN}Efetuando Push.${NC}"
echo -e "\n7) ${RED}Por favor, digite sua senha novamente:${NC}"
# git push -v --porcelain >> logs/logPush.log 2>&1


# Verificar o retorno do comando GIT Push, caso retorne algo diferente de 0, entrará em estado de erro e finalizará o processo.
# if grep -q -w -i "Rejected" logs/logPush.log ;
if [ ! git push -v --porcelain >> libs/logs/logPush.log 2>&1 ]; then 
	echo -e " ${RED}Conflito de push encontrado.${NC} \nLog do erro em: libs/logs/ - Por favor corrija e efetue o push novamente."
	echo -e "Pressione ENTER p/ finalizar."
	read
	exit
else
	apagarLogs=true
fi


# Deletar Logs criados quando não houver nenhum problema de envio ao servidor
if [ "${apagarLogs}" = true ]; then
	rm -f "${currentDir}"libs/logs/log*
else
	:
fi

echo -e "\n8) ${GREEN}Processo finalizado, suas alteracoes foram enviadas com sucesso!${NC}\n"

#FIM
exit 0
