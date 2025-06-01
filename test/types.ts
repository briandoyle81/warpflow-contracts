export type ShipTraits = {
  serialNumber: bigint;
  colors: {
    h1: number;
    s1: number;
    l1: number;
    h2: number;
    s2: number;
    l2: number;
  };
  variant: number;
  accuracy: number;
  hull: number;
  speed: number;
};

export type ShipEquipment = {
  mainWeapon: number;
  armor: number;
  shields: number;
  special: number;
};

export type ShipData = {
  constructed: boolean;
  inFleet: boolean;
  timestampDestroyed: bigint;
  shiny: boolean;
  shipsDestroyed: number;
  costsVersion: number;
  cost: number;
};

// This type represents the tuple returned by the contract
export type ShipTuple = [
  string, // name
  bigint, // id
  ShipEquipment, // equipment
  ShipTraits, // traits
  ShipData, // shipData
  `0x${string}` // owner
];

// Helper function to convert tuple to Ship object
export function tupleToShip(tuple: ShipTuple): Ship {
  return {
    name: tuple[0],
    id: tuple[1],
    equipment: tuple[2],
    traits: tuple[3],
    shipData: tuple[4],
    owner: tuple[5],
  };
}

export type Ship = {
  name: string;
  id: bigint;
  equipment: ShipEquipment;
  traits: ShipTraits;
  shipData: ShipData;
  owner: `0x${string}`;
};
