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
        uint _costLimit
    ) external returns (uint) {
        if (msg.sender != lobbiesAddress) revert NotLobbiesContract();

        uint totalCost = 0;
        fleetCount++;
        uint fleetId = fleetCount;

        Fleet storage newFleet = fleets[fleetId];
        newFleet.id = fleetId;
        newFleet.lobbyId = _lobbyId;
        newFleet.owner = _owner;
        newFleet.shipIds = _shipIds;

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

    function getFleetShipIds(
        uint _fleetId
    ) external view returns (uint[] memory) {
        if (fleets[_fleetId].id == 0) revert FleetNotFound();
        return fleets[_fleetId].shipIds;
    }
}
