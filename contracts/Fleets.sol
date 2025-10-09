// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Types.sol";
import "./Ships.sol";
import "./IFleets.sol";

contract Fleets is Ownable, IFleets {
    Ships public ships;
    address public lobbiesAddress;
    address public gameAddress;

    mapping(uint => Fleet) public fleets;
    uint public fleetCount;

    event FleetCreated(
        uint indexed fleetId,
        uint indexed lobbyId,
        address indexed owner
    );
    event FleetCleared(uint indexed fleetId);

    error NotLobbiesContract();
    error FleetNotFound();
    error ShipNotOwned();
    error ShipAlreadyInFleet();
    error ShipCostVersionMismatch();
    error InvalidFleetCost();
    error ShipNotFound();
    error DuplicatePosition();
    error ArrayLengthMismatch();
    error InvalidPosition();

    constructor(address _ships) Ownable(msg.sender) {
        ships = Ships(_ships);
    }

    function setLobbiesAddress(address _lobbiesAddress) public onlyOwner {
        lobbiesAddress = _lobbiesAddress;
    }

    function setGameAddress(address _gameAddress) public onlyOwner {
        gameAddress = _gameAddress;
    }

    function createFleet(
        uint _lobbyId,
        address _owner,
        uint[] calldata _shipIds,
        Position[] calldata _startingPositions,
        uint _costLimit,
        bool _isCreator
    ) external returns (uint) {
        if (msg.sender != lobbiesAddress) revert NotLobbiesContract();

        // Validate that shipIds and startingPositions arrays have the same length
        if (_shipIds.length != _startingPositions.length)
            revert ArrayLengthMismatch();

        // Validate positions based on whether this is creator or joiner fleet
        for (uint i = 0; i < _startingPositions.length; i++) {
            Position memory pos = _startingPositions[i];

            if (_isCreator) {
                // Creator ships must be in columns 0-4 (first 5 columns)
                if (pos.col < 0 || pos.col > 4) revert InvalidPosition();
            } else {
                // Joiner ships must be in columns 20-24 (last 5 columns)
                if (pos.col < 20 || pos.col > 24) revert InvalidPosition();
            }

            // Validate row bounds (0-12 for 13 rows)
            if (pos.row < 0 || pos.row > 12) revert InvalidPosition();
        }

        uint totalCost = 0;
        fleetCount++;
        uint fleetId = fleetCount;

        Fleet storage newFleet = fleets[fleetId];
        newFleet.id = fleetId;
        newFleet.lobbyId = _lobbyId;
        newFleet.owner = _owner;
        newFleet.shipIds = _shipIds;

        // Copy startingPositions array element by element
        for (uint i = 0; i < _startingPositions.length; i++) {
            newFleet.startingPositions.push(_startingPositions[i]);
        }

        // Validate ships and calculate total cost
        for (uint i = 0; i < _shipIds.length; i++) {
            uint shipId = _shipIds[i];
            Ship memory ship = ships.getShip(shipId);

            // Validate ship ownership
            if (ship.owner != _owner) revert ShipNotOwned();

            // Validate ship is not in another fleet
            if (ship.shipData.inFleet) revert ShipAlreadyInFleet();

            // Validate cost version
            if (ship.shipData.costsVersion != ships.getCurrentCostsVersion())
                revert ShipCostVersionMismatch();

            totalCost += ship.shipData.cost;
        }

        // Validate total cost
        if (totalCost > _costLimit) revert InvalidFleetCost();

        newFleet.totalCost = totalCost;
        newFleet.isComplete = true;

        // Validate that no positions are duplicated anywhere in the array
        // O(n), all in memory, no storage writes
        // Use bitset for 25×13 grid (325 positions max)
        uint256[2] memory positionBitset; // 2 * 256 = 512 bits > 325 positions

        for (uint i = 0; i < _startingPositions.length; i++) {
            Position memory pos = _startingPositions[i];

            // Convert position to single key: row * GRID_WIDTH + col
            uint256 key = uint256(int256(pos.row)) *
                25 +
                uint256(int256(pos.col));

            // Check if position already seen
            uint256 wordIndex = key / 256;
            uint256 bitIndex = key % 256;

            if ((positionBitset[wordIndex] & (1 << bitIndex)) != 0) {
                revert DuplicatePosition();
            }

            // Mark position as seen
            positionBitset[wordIndex] |= (1 << bitIndex);
        }

        // Mark ships as in fleet
        for (uint i = 0; i < _shipIds.length; i++) {
            ships.setInFleet(_shipIds[i], true);
        }

        emit FleetCreated(fleetId, _lobbyId, _owner);
        return fleetId;
    }

    function clearFleet(uint _fleetId) external {
        if (msg.sender != lobbiesAddress) revert NotLobbiesContract();

        Fleet storage fleet = fleets[_fleetId];
        if (fleet.id == 0) revert FleetNotFound();

        // Release ships from fleet
        for (uint i = 0; i < fleet.shipIds.length; i++) {
            ships.setInFleet(fleet.shipIds[i], false);
        }

        // Clear the fleet's shipIds array
        delete fleet.shipIds;

        emit FleetCleared(_fleetId);
    }

    function removeShipFromFleet(uint _fleetId, uint _shipId) external {
        if (msg.sender != lobbiesAddress && msg.sender != gameAddress)
            revert NotLobbiesContract();

        Fleet storage fleet = fleets[_fleetId];
        if (fleet.id == 0) revert FleetNotFound();

        // Find and remove the ship from the fleet
        for (uint i = 0; i < fleet.shipIds.length; i++) {
            if (fleet.shipIds[i] == _shipId) {
                // Remove ship from array by shifting elements
                for (uint j = i; j < fleet.shipIds.length - 1; j++) {
                    fleet.shipIds[j] = fleet.shipIds[j + 1];
                }
                fleet.shipIds.pop();

                // Release ship from fleet
                ships.setInFleet(_shipId, false);

                // Update total cost
                Ship memory ship = ships.getShip(_shipId);
                fleet.totalCost -= ship.shipData.cost;

                return;
            }
        }

        // Ship not found in fleet
        revert ShipNotFound();
    }

    // View functions
    function getFleet(uint _fleetId) external view returns (Fleet memory) {
        if (fleets[_fleetId].id == 0) revert FleetNotFound();
        return fleets[_fleetId];
    }

    // Check if a ship is in a specific fleet
    function isShipInFleet(
        uint _fleetId,
        uint _shipId
    ) external view returns (bool) {
        if (fleets[_fleetId].id == 0) revert FleetNotFound();

        Fleet memory fleet = fleets[_fleetId];
        for (uint i = 0; i < fleet.shipIds.length; i++) {
            if (fleet.shipIds[i] == _shipId) {
                return true;
            }
        }
        return false;
    }

    function getFleetShipIdsAndPositions(
        uint _fleetId
    )
        external
        view
        returns (uint[] memory shipIds, Position[] memory startingPositions)
    {
        if (fleets[_fleetId].id == 0) revert FleetNotFound();
        Fleet memory fleet = fleets[_fleetId];
        return (fleet.shipIds, fleet.startingPositions);
    }
}
