import { STACKS_API_URL } from './constants';

export const sleep = (ms: number) => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

export const wait_until_confirmation = async (txid: string) => {
  while (true) {
    await sleep(3000);
    let truth = await fetch(`${STACKS_API_URL()}/extended/v1/tx/0x${txid}`);
    let res = await truth.json();
    console.log(`Waiting for confirmation... ${txid}`);
    if (res['tx_status'] === 'success') {
      console.log('Transaction completed successfully');
      return true;
    } else if (res['tx_status'] === 'abort_by_response') {
      console.log('Transaction aborted: ', res['tx_result']['repr']);
      return false;
    } else if (res.hasOwnProperty('error')) {
      console.log('Transaction aborted: ', res['error']);
      return false;
    }
  }
};

export function format_number(number: number, fixed = 2) {
  return number.toFixed(fixed).replace(/\d(?=(\d{3})+\.)/g, '$&,');
}

const fromHexString = (hexString: string) =>
  new Uint8Array(hexString.match(/.{1,2}/g)!.map(byte => parseInt(byte, 16)));

export function timestamp() {
  // Create a date object with the current time
  var now = new Date();

  // Create an array with the current month, day and time
  var date = [now.getMonth() + 1, now.getDate(), now.getFullYear()];

  // Create an array with the current hour, minute and second
  var time = [now.getHours(), now.getMinutes(), now.getSeconds()];

  // Determine AM or PM suffix based on the hour
  var suffix = time[0] < 12 ? 'AM' : 'PM';

  // Convert hour from military time
  time[0] = time[0] < 12 ? time[0] : time[0] - 12;

  // If hour is 0, set it to 12
  time[0] = time[0] || 12;

  // If seconds and minutes are less than 10, add a zero
  for (var i = 1; i < 3; i++) {
    if (time[i] < 10) {
      // @ts-ignore
      time[i] = '0' + time[i];
    }
  }

  // Return the formatted string
  return date.join('/') + ' ' + time.join(':') + ' ' + suffix;
}
