pragma solidity ^0.4.24;

contract Fisticuffs {
    enum State {
        Setup,
        Active,
        Ended
    }
    State public state;

    modifier inState(State s) {
        require(state == s);
        _;
    }


    struct Square {
        int8[4] gentlemenInSquare; // -1 represents null, 0+ represents iterator of gentleman
    }
    Square[8][8] map;

    function getGentlemenInSquare(uint8 x, uint8 y)
    view
    internal
    returns(int8[4]) {
        return map[x][y].gentlemenInSquare;
    }


    address public GameMaster;

    constructor() {
        GameMaster = msg.sender;
        state = State.Setup;
        for (uint8 x=0; x<8; x++) {
            for (uint8 y=0; y<8; y++) {
                for (uint8 i=0; i<4; i++) {
                    map[x][y].gentlemenInSquare[i] = -1;
                }
            }
        }
    }

    modifier onlyGameMaster() {
        require(msg.sender == GameMaster);
        _;
    }


    struct VictorianGentleman {
        address owner;
        uint8[2] position;
        uint8 health;
        uint8 energy;
    }

    VictorianGentleman[16] public victorianGentlemen;
    function getGentlemanPosition(uint8 ID)
    view
    public
    returns (uint8[2]) {
        return victorianGentlemen[ID].position;
    }


    function assignOwners(address[16] owners)
    external
    onlyGameMaster
    inState(State.Setup) {
        for (uint8 i=0; i<16; i++) {
            victorianGentlemen[i].owner = owners[i];
        }
    }

    modifier onlyGentlemanOwner(uint8 gentlemanID) {
        require(msg.sender == victorianGentlemen[gentlemanID].owner);
        _;
    }

    function initiateGame()
    external
    onlyGameMaster
    inState(State.Setup) {
        for (uint8 i=0; i<16; i++) {
            victorianGentlemen[i].position[0] = (i%4)*2;
            victorianGentlemen[i].position[1] = (i/4)*2;
            map[victorianGentlemen[i].position[0]][victorianGentlemen[i].position[1]].gentlemenInSquare[0] = int8(i);
            victorianGentlemen[i].health = 255;
            victorianGentlemen[i].energy = 255;
        }

        state = State.Active;
    }


    function positionInBounds(uint8[2] position)
    pure
    internal
    returns(bool) {
        return (position[0] >= 0 && position[0] <= 15 && position[1] >= 0 && position[1] <= 15);
    }


    enum Direction {Right, Left, Up, Down}
    function commandMove(uint8 gentlemanID, Direction d)
    external
    onlyGentlemanOwner(gentlemanID) {
        uint8[2] newPosition = victorianGentlemen[gentlemanID].position;
        if (d == Direction.Right) {
            newPosition[0] += 1;
        }
        else if (d == Direction.Left) {
            newPosition[0] -= 1;
        }
        else if (d == Direction.Down) {
            newPosition[0] += 1;
        }
        else if (d == Direction.Up) {
            newPosition[0] -= 1;
        }

    }
}
