const STACKS_API_URL = () => {
    if (process.env.STACKS_API_URL) {
        return process.env.STACKS_API_URL;
    }

    throw new Error(`STACKS_API_URL is not defined`);
}

module.exports = {
    STACKS_API_URL
}
