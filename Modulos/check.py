
          

from datetime import datetime

from flask import Flask, jsonify, request
import os
import typing as t

app = Flask(__name__)




def run_command(username: str, action: int) -> t.Optional[str]:
    try:
        command = f'check {username} {action}'
        result = os.popen(command).readlines()
        final = result[0].strip()
        return final
    except Exception as e:
        print(f"Erro ao executar comando para {username}: {e}")
        return None



def user_usuario(username: str) -> t.Optional[str]:
    return run_command(username, 1)



def user_conectados(username: str) -> t.Optional[str]:
    return run_command(username, 2)



def user_limite(username: str) -> t.Optional[str]:
    return run_command(username, 3)



def user_data(username: str) -> t.Optional[str]:
    return run_command(username, 4)



def user_dias_restantes(username: str) -> t.Optional[str]:
    return run_command(username, 5)



def format_date_for_anymod(date_string):
    date = datetime.strptime(date_string, "%d/%m/%Y")
    formatted_date = date.strftime("%Y-%m-%d-")
    return formatted_date


          


@app.route('/checkUser', methods=['POST', 'GET'])
def c4g():
    if request.method == 'POST':
        try:
            req_data = request.get_json()
            username = user_usuario(req_data.get("user"))

            if username == "Not exist":
                user_info = {
                    "username": username,
                    "count_connection": None,
                    "expiration_date": None,
                    "expiration_days": None,
                    "limiter_user": None
                }
            else:
                user_info = {
                    "username": username,
                    "count_connection": user_conectados(username),
                    "expiration_date": user_data(username),
                    "expiration_days": user_dias_restantes(username),
                    "limiter_user": user_limite(username)
                }
            return user_info

        except Exception as e:
            return jsonify({'error': str(e)})
    else:
        try:
            return 'Por favor, use o metodo de requisição correto ! \n\n Checkuser CONECTA4G'
        except Exception as e:
            return jsonify({'error': str(e)})



@app.route('/gl/check/<username>', methods=['POST', 'GET'])
def gl(username):
    if request.method == 'GET':
        try:
            if username == "Not exist":
                user_info = {
                    "username": username,
                    "count_connection": None,
                    "expiration_date": None,
                    "expiration_days": None,
                    "limit_connection": None
                }
            else:
                user_info = {
                    "username": username,
                    "count_connection": user_conectados(username),
                    "expiration_date": user_data(username),
                    "expiration_days": user_dias_restantes(username),
                    "limit_connection": user_limite(username)
                }
            return user_info

        except Exception as e:
            return jsonify({'error': str(e)})
    else:
        try:
            return 'Por favor, use o método de requisição correto! \n\n Checkuser GL'
        except Exception as e:
            return jsonify({'error': str(e)})



@app.route('/anymod', methods=['POST', 'GET'])
def anymod():
    if request.method == 'POST':
        try:
            data = request.form
            username = data.get('username')
            deviceid = data.get('deviceid')
            user = user_usuario(username)
            if user == "Not exist":
                return jsonify({
                    "USER_ID": username,
                    "DEVICE": deviceid,
                    "is_active": "false",
                    "Status": "naoencontrado",
                    "uuid": "null"
                })
            else:
                online = user_conectados(user)
                limite = user_limite(user)
                device = "false" if online > limite else deviceid
                is_active = "false" if online > limite else "true"
                return jsonify({
                    "USER_ID": username,
                    "DEVICE": device,
                    "is_active": is_active,
                    "expiration_date": format_date_for_anymod(user_data(user)),
                    "expiry": f"{user_dias_restantes(user)} dias.",
                    "uuid": "null"
                })
        except Exception as e:
            return jsonify({'error': str(e)})
    else:
        try:
            return 'Por favor, use o método de requisição correto! \n\n Checkuser ANY VPN MOD'
        except Exception as e:
            return jsonify({'error': str(e)})



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9999)

          
