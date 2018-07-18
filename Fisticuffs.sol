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

    function findGentlemanIDInSquare(uint8 x, uint8 y, int8 gentlemanID)
    view
    internal
    returns (int8) {
        for (uint8 i=0; i<4; i++) {
            if (map[x][y].gentlemenInSquare[i] == gentlemanID) {
                return int8(i);
            }
        }
        return -1;
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
        address owner; // If owner == 0x0, this is a null gentlemen
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

    function initializeGame()
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


    function deductEnergyOrRevert(uint8 gentlemanID, uint8 amount)
    internal {
        if (victorianGentlemen[gentlemanID].energy < amount) {
            revert("Trying to spend too much energy!");
        }
        else {
            victorianGentlemen[gentlemanID].energy -= amount;
        }
    }

    function deductHealthOrKill(uint8 gentlemanID, uint8 amount)
    internal {
        if (victorianGentlemen[gentlemanID].health < amount) {
            uint8 tileX = victorianGentlemen[gentlemanID].position[0];
            uint8 tileY = victorianGentlemen[gentlemanID].position[1];

            int8 castedGentlemanID = int8(gentlemanID);
            require(castedGentlemanID >= 0, "Error casting Gentleman ID: negative result");

            //de-register from square
            int8 iter = findGentlemanIDInSquare(tileX, tileY, castedGentlemanID);
            assert(iter >= 0); // If logic is working expectedly, this should never fail (this is why assert is used over require)

            map[tileX][tileY].gentlemenInSquare[uint(iter)] = -1;

            //null out the gentleman
            victorianGentlemen[gentlemanID].owner = 0x0;
        }
        else {
            victorianGentlemen[gentlemanID].health -= amount;
        }
    }


    enum Direction {Right, Left, Up, Down}

    function commandMove(uint8 gentlemanID, Direction d)
    external
    onlyGentlemanOwner(gentlemanID)
    inState(State.Active) {
        deductEnergyOrRevert(gentlemanID, 10);

        //The line below is not strictly necessary, as the onlyGentlemanOwner modifier indirectly checks this
        //require(victorianGentlemen[gentlemanID].owner != 0x0);

        uint8[2] memory oldPosition = victorianGentlemen[gentlemanID].position;
        uint8[2] memory newPosition = oldPosition;
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
        require(positionInBounds(newPosition), "Invalid move! Can't move outside of the map.");

        int8 emptySlot = findGentlemanIDInSquare(newPosition[0], newPosition[1], -1);
        require(emptySlot != -1, "That square is full!");

        for (int8 i=0; i<4; i++) {
            int8 castedGentlemanID = int8(gentlemanID);
            require(castedGentlemanID >= 0);

            if (map[oldPosition[0]][oldPosition[1]].gentlemenInSquare[uint(i)] == castedGentlemanID) {
                map[oldPosition[0]][oldPosition[1]].gentlemenInSquare[uint(i)] = -1; // set to null
            }
        }

        map[newPosition[0]][newPosition[1]].gentlemenInSquare[uint(emptySlot)] = castedGentlemanID;

        victorianGentlemen[gentlemanID].position = newPosition;
    }

    function punch(uint8 punchingGentlemenID, uint8 targetedGentlemanID) {
        deductEnergyOrRevert(punchingGentlemenID, 30);

        uint8 tileX = victorianGentlemen[punchingGentlemenID].position[0];
        uint8 tileY = victorianGentlemen[punchingGentlemenID].position[1];

        int8 castedTargetedGentlemanID = int8(targetedGentlemanID);
        require(castedTargetedGentlemanID >= 0, "Error casting targeted Gentleman ID: negative result");

        int8 targetIter = findGentlemanIDInSquare(tileX, tileY, castedTargetedGentlemanID);
        require(targetIter != -1, "Target is not in the same square as the puncher!");

        deductHealthOrKill(targetedGentlemanID, 15);
    }
}
