from flask import Flask, jsonify, request
from DQN import DQNAgent
import os
os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"   # see issue #152
os.environ["CUDA_VISIBLE_DEVICES"] = ""

app = Flask(__name__)

num_state = 18
num_action = 8
num_hidden_node = [120,120]
# m = 

dqn_agent = DQNAgent(num_state,num_action,num_hidden_node)

@app.route('/model', methods=['GET'])
def get_model():
    return jsonify(dqn_agent.get_model())

    
    # return "test"

@app.route('/update', methods=['POST'])
def update():

    dqn_agent.run(request.json)
    print("finish run")
    return jsonify(dqn_agent.get_model())


    
# @app.route('/CreepBlockAI/dump', methods=['GET'])
# def dump():
#     m.dump()
#     return jsonify({})
    
# @app.route('/CreepBlockAI/load', methods=['POST'])
# def load():
#     m.load(request.json['file'])
#     return jsonify({})
    
if __name__ == '__main__':  
    app.run(debug=False)