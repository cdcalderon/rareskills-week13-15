const fs = require("fs");
const path = require("path");
const solc = require("solc");

const CONTRACT_FILE_NAME = "YULRC1155.yul";
const BYTECODE_FILE_NAME = "YULRC1155.bytecode.json";
const CONTRACT_DIRECTORY = path.resolve(__dirname, "..", "contracts");

/**
 * This function accomplishes three tasks:
 * 1. Compiles the YULRC1155 smart contract written in Yul language.
 * 2. Writes the bytecode output of the compiled contract to a JSON file named 'YULRC1155.bytecode.json'.
 * 3. Returns the compiled bytecode as a string.
 *
 * @returns {String} The bytecode of the compiled YULRC1155 smart contract.
 */

async function compileYULRC1155() {
  const input = {
    language: "Yul",
    sources: {
      [CONTRACT_FILE_NAME]: {
        content: fs.readFileSync(
          path.join(CONTRACT_DIRECTORY, CONTRACT_FILE_NAME),
          "utf8"
        ),
      },
    },
    settings: {
      outputSelection: {
        "*": {
          "*": ["*"],
        },
      },
    },
  };

  const output = JSON.parse(solc.compile(JSON.stringify(input)));
  const {
    evm: { bytecode },
  } = output.contracts[CONTRACT_FILE_NAME].YULRC1155;

  fs.writeFileSync(
    path.join(CONTRACT_DIRECTORY, BYTECODE_FILE_NAME),
    JSON.stringify(bytecode),
    (err) => {
      if (err) console.error(err);
    }
  );

  return bytecode.object;
}

/**
 * This function retrieves the bytecode of the YULRC1155 contract. It follows these steps:
 * 1. Checks if the bytecode has been previously compiled and stored in a JSON file named 'YULRC1155.bytecode.json'.
 * 2. If the file exists, the function reads the file and returns the bytecode contained within it.
 * 3. If the file does not exist, the function recompiles the YULRC1155 contract, generates the bytecode, and returns it.
 *
 * @returns {String} Bytecode of the YULRC1155 smart contract.
 */

async function getYULRC1155Bytecode() {
  const bytecodeFilePath = path.join(CONTRACT_DIRECTORY, BYTECODE_FILE_NAME);

  let bytecode;

  if (fs.existsSync(bytecodeFilePath)) {
    const bytecodeFileContents = fs.readFileSync(bytecodeFilePath);
    bytecode = JSON.parse(bytecodeFileContents).object;
  } else {
    bytecode = await compileYULRC1155();
  }

  return bytecode;
}

module.exports = {
  getYULRC1155Bytecode,
};
