import { ethers } from "hardhat";
import { Solar } from "../typechain-types/Solar";

describe("Test", function () {
    let solar: Solar;
    beforeEach(async () => {
        const solarFactory = await ethers.getContractFactory("Solar");
        solar = await solarFactory.deploy() as Solar;
    })
    it("Test", async function () {
        await solar.setROI(50, 10);
        console.log(await solar.getROI());
    })
})