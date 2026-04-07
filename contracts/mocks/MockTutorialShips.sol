// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../ITutorialShips.sol";
import "../Types.sol";

contract MockTutorialShips is ITutorialShips {
    uint public nextId = 1;
    mapping(address => uint[]) private ownerToShipIds;
    mapping(uint => Ship) public shipsById;

    function createSpecificShip(
        address _to,
        Ship calldata _ship
    ) external override returns (uint) {
        uint newId = nextId++;
        ownerToShipIds[_to].push(newId);

        Ship storage s = shipsById[newId];
        s.id = newId;
        s.name = _ship.name;
        s.equipment = _ship.equipment;
        s.traits = _ship.traits;
        s.owner = _to;
        return newId;
    }

    function getShip(uint _id) external view returns (Ship memory) {
        return shipsById[_id];
    }

    function getShipIdsOwned(address _owner) external view returns (uint[] memory) {
        return ownerToShipIds[_owner];
    }
}
