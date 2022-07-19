const { SignerWithAddress } = require("@nomiclabs/hardhat-ethers/signers");
const { BigNumber, Contract, ContractFactory } = require("ethers");
const { starknet, network, ethers } = require("hardhat");

const { expect } = require("chai");
const { clearConfigCache } = require("prettier");

describe("multiSender", function () {
  let tokenOwner;
  let tokenReceiver_1;
  let erc20_erc721_contractOwner;

  let multiSenderContract;
  let erc20Contract;
  let erc721Contract;
  let fooContract;
  let RECEIVERS;

  before(async function () {
    const signers = await ethers.getSigners();

    tokenOwner = signers[0];

    tokenReceiver_1 = signers[1];
    tokenReceiver_2 = signers[4];
    tokenReceiver_3 = signers[5];
    tokenReceiver_4 = signers[6];
    RECEIVERS = [
      tokenReceiver_1,
      tokenReceiver_2,
      tokenReceiver_3,
      tokenReceiver_4,
    ];

    erc20_erc721_contractOwner = signers[2];

    multiSenderOnwer = signers[3];

    //deploy erc20 contract
    let fooFactory = await ethers.getContractFactory(
      "foo",
      erc20_erc721_contractOwner
    );

    fooContract = await fooFactory.deploy();
    await fooContract.deployed();

    //deploy erc20 contract
    let erc20MintableFactory = await ethers.getContractFactory(
      "ERC20Mintable",
      erc20_erc721_contractOwner
    );

    erc20Contract = await erc20MintableFactory.deploy();
    await erc20Contract.deployed();

    erc20Contract.connect();
    //get and deploy multiSender contract
    let multiSenderFactory = await ethers.getContractFactory(
      "multiSender",
      multiSenderOnwer
    );
    multiSenderContract = await multiSenderFactory.deploy();
    await multiSenderContract.deployed();

    //deploy erc721 contract
    let erc721Factory = await ethers.getContractFactory(
      "ERC721MintableBurnable",
      erc20_erc721_contractOwner
    );
    erc721Contract = await erc721Factory.deploy("NFT", "TNFT");
    await erc721Contract.deployed();
  });

  it("test new function", async function () {
    multiSenderContract = multiSenderContract.connect(tokenOwner);
    await expect(
      multiSenderContract.multisender(
        "0x0000000000000000000000000000000000000000",
        ["0x0000000000000000000000000000000000000000"],
        ["1"],
        ["1"]
      )
    ).to.be.reverted;
  });

  it("mint", async function () {
    console.log("minting erc20");
    await erc20Contract.mint(tokenOwner.address, 9999);
    let balance = await erc20Contract.balanceOf(tokenOwner.address);
    console.log("tokenOwner's balance: ", balance);
  });

  it("mint NFT", async function () {
    console.log("minting 100 test NFTS....!");
    for (let index = 0; index < 100; index++) {
      await erc721Contract.mint(
        tokenOwner.address,
        index,
        "Qmb6tWBDLd9j2oSnvSNhE314WFL7SRpQNtfwjFWsStXp5A"
      );
    }
    let balance = await erc721Contract.balanceOf(tokenOwner.address);
    console.log("tokenOwner's NFT balance: ", balance);
  });

  it("Send ERC20 token by multiSender contract", async function () {
    //send by tokenOwner
    console.log("sending erc20 tokens to multi-address.....");
    multiSenderContract = multiSenderContract.connect(tokenOwner);
    erc20Contract = await erc20Contract.connect(tokenOwner);

    let receiver = [
      tokenReceiver_1.address,
      tokenReceiver_2.address,
      tokenReceiver_3.address,
      tokenReceiver_4.address,
    ];

    let failReceiver = [false, false, true, true];
    let amountArrayFail = [1000, 3000, 500, 500];
    let amountArray = [1000, 2000, 500, 500];

    console.log("amount ERC20 will be sent: ", amountArray);

    let totalSendValue = 0;
    amountArray.forEach((element) => {
      totalSendValue += element;
    });

    multiSenderContract = multiSenderContract.connect(tokenOwner);
    console.log(
      "approve for multiSender contract to send %s ERC20 token...",
      totalSendValue
    );

    //aprove to send token
    await erc20Contract.approve(multiSenderContract.address, totalSendValue);

    console.log("ERC20 token balance of receivers BEFORE send:");
    let balanceBeforeArray = [];
    for (let index = 0; index < receiver.length; index++) {
      let blanceBeforeOfReceiver = await await erc20Contract.balanceOf(
        receiver[index]
      );
      balanceBeforeArray.push(blanceBeforeOfReceiver);
      console.log(
        "                    + receiver %s: ",
        index,
        blanceBeforeOfReceiver
      );
    }

    //send to multi-address

    await multiSenderContract.multisender(
      erc20Contract.address,
      receiver,
      [],
      amountArrayFail
    );

    console.log("ERC20 token balance of receivers AFTER send:");
    for (let index = 0; index < receiver.length; index++) {
      let blanceAfterOfReceiver = await await erc20Contract.balanceOf(
        receiver[index]
      );

      console.log(
        "                    + receiver %s: ",
        index,
        blanceAfterOfReceiver
      );
      if (!failReceiver[index]) {
        expect(blanceAfterOfReceiver.sub(balanceBeforeArray[index])).to.equal(
          BigNumber.from(amountArrayFail[index])
        );
      } else {
        expect(blanceAfterOfReceiver).to.equal(balanceBeforeArray[index]);
      }
    }
  });

  it("ether", async function () {
    multiSenderContract = multiSenderContract.connect(tokenOwner);
    // let receiver = [tokenReceiver_1.address, tokenReceiver_1.address];
    let receiver = [
      tokenReceiver_1.address,
      tokenReceiver_2.address,
      tokenReceiver_3.address,
      tokenReceiver_4.address,
    ];

    let amountArray = [10000, 30000, 25000, 35000]; //TODO: DELETE

    let failReceiver = [false, false, true, false];

    let amountArrayFail = [10000, 30000, 75000, 35000];
    //total sent-value
    let totalSendValue = 0;
    amountArray.forEach((element) => {
      totalSendValue += element;
    });

    totalSendValue = 100000; //TODO: DELETE

    let balanceOfSenderBefore = await tokenOwner.getBalance();

    let estimateGas = await multiSenderContract.estimateGas.multisender(
      "0x0000000000000000000000000000000000000000",
      receiver,
      [],
      amountArrayFail,
      {
        value: BigNumber.from(totalSendValue),
      }
    );

    let gasPrice = await multiSenderContract.provider.getGasPrice();
    let gasFee = estimateGas * gasPrice;
    // console.log('estimateGasFee:  ', gasFee);
    let totalSpend = totalSendValue + gasFee;

    if (totalSpend > balanceOfSenderBefore) {
      throw Error("Not enought ETH to send!");
    }

    console.log("ETH(wei) balance of receivers BEFORE send:");
    let balanceBeforeArray = [];
    for (let index = 0; index < RECEIVERS.length; index++) {
      let blanceBeforeOfReceiver = await RECEIVERS[index].getBalance();
      balanceBeforeArray.push(blanceBeforeOfReceiver);
      console.log(
        "                    + receiver %s: ",
        index,
        blanceBeforeOfReceiver
      );
    }

    await multiSenderContract.multisender(
      "0x0000000000000000000000000000000000000000",
      receiver,
      [],
      amountArrayFail,
      {
        value: BigNumber.from(totalSendValue),
        // gasLimit: estimateGas,
      }
    );

    console.log("ETH(wei) balance of receivers AFTER send:");
    for (let index = 0; index < RECEIVERS.length; index++) {
      let blanceAfterOfReceiver = await RECEIVERS[index].getBalance();
      console.log(
        "                    + receiver %s: ",
        index,
        blanceAfterOfReceiver
      );
      //expect increasing value after send have to be equal to sent-value
      if (!failReceiver[index]) {
        expect(blanceAfterOfReceiver.sub(balanceBeforeArray[index])).to.equal(
          BigNumber.from(amountArrayFail[index])
        );
      } else {
        expect(blanceAfterOfReceiver).to.equal(balanceBeforeArray[index]);
      }
    }

    multiSenderContractBalance = await multiSenderContract.getBalance();

    console.log("multiSenderContractBalance: ", multiSenderContractBalance);
  });

  it("approve multisender to transfer NFTs", async function () {
    //change signer to tokenOwner
    erc721Contract = await erc721Contract.connect(tokenOwner);
    //approve transfer
    // await erc721Contract.setApprovalForAll(multiSenderContract.address, true);
    await erc721Contract.approve(multiSenderContract.address, "1");
    await erc721Contract.approve(multiSenderContract.address, "3");
    await erc721Contract.approve(multiSenderContract.address, "50");
    await erc721Contract.approve(multiSenderContract.address, "79");
  });

  it("transfer NFTs by multisender", async function () {
    //send by tokenOwner

    multiSenderContract = multiSenderContract.connect(tokenOwner);
    let receivers = [
      tokenReceiver_1.address,
      // tokenReceiver_2.address,
      fooContract.address,
      tokenReceiver_3.address,
      tokenReceiver_4.address,
    ];
    let tokenIds = ["1", "3", "50", "79"];
    let revertTokenIds = [false, true, false, false];

    console.log("NFT balance of receivers BEFORE send:");
    let balanceBeforeArray = [];
    for (let index = 0; index < receivers.length; index++) {
      let blanceBeforeOfReceiver = await erc721Contract.balanceOf(
        receivers[index]
      );
      balanceBeforeArray.push(blanceBeforeOfReceiver);
      console.log(
        "                    + receiver %s: ",
        index,
        blanceBeforeOfReceiver
      );
    }

    await multiSenderContract.multisender(
      erc721Contract.address,
      receivers,
      tokenIds,
      []
    );

    console.log("NFT balance of receivers AFTER send:");
    for (let index = 0; index < receivers.length; index++) {
      let blanceAfterOfReceiver = await erc721Contract.balanceOf(
        receivers[index]
      );
      console.log(
        "                    + receiver %s: ",
        index,
        blanceAfterOfReceiver
      );

      if (!revertTokenIds[index]) {
        expect(await erc721Contract.ownerOf(tokenIds[index])).to.equal(
          receivers[index]
        );
      } else {
        expect(await erc721Contract.ownerOf(tokenIds[index])).to.equal(
          tokenOwner.address
        );
      }
    }
  });

  it("remove approved operator", async function () {
    //change signer to tokenOwner
    erc721Contract = await erc721Contract.connect(tokenOwner);
    //approve transfer
    await erc721Contract.setApprovalForAll(multiSenderContract.address, false);
  });

  it("transfer NFT tokenID 10,20,40,69 after removed operater", async function () {
    multiSenderContract = multiSenderContract.connect(tokenOwner);
    let receivers = [
      tokenReceiver_1.address,
      tokenReceiver_2.address,
      tokenReceiver_3.address,
      tokenReceiver_4.address,
    ];
    let tokenIds = [10, 20, 40, 69];

    for (let index = 0; index < receivers.length; index++) {
      let blanceAfterOfReceiver = await erc721Contract.balanceOf(
        receivers[index]
      );
      console.log(
        "                    + receiver %s: ",
        index,
        blanceAfterOfReceiver
      );

      expect(await erc721Contract.ownerOf(tokenIds[index])).to.equal(
        tokenOwner.address
      );
    }
  });
});
