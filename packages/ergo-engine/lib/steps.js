/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

const Fs = require('fs');
const Path = require('path');

const Chai = require('chai');
const expect = Chai.expect;

const Moment = require('moment');

const TemplateLogic = require('@accordproject/ergo-compiler').TemplateLogic;
const Engine = require('./engine');
const Util = require('./util');

const { Before, Given, When, Then } = require('cucumber');

/**
 * Compare actual result and expected result
 *
 * @param {string} expected the result as specified in the test workload
 * @param {string} actual the result as returned by the engine
 */
function compare(expected,actual) {
    for (const key in expected) {
        const field = key;
        const expectedValue = expected[key];
        expect(actual).to.have.property(field);
        const actualValue = Moment.isMoment(actual[field]) ? actual[field].format() : actual[field];
        expect(actualValue).to.deep.equal(expectedValue);
    }
}

/**
 * Invoke Ergo contract initialization
 *
 * @param {object} engine - the execution engine
 * @param {object} templateLogic - the Template Logic
 * @param {object} contractJson contract data in JSON
 * @param {string} currentTime the definition of 'now'
 * @returns {object} Promise to the initial state of the contract
 */
function init(engine,templateLogic,contractJson,currentTime) {
    templateLogic.compileLogic();
    return engine.init(templateLogic,templateLogic.getContractName(),contractJson,currentTime);
}

/**
 * Execute the Ergo contract with a request
 *
 * @param {object} engine - the execution engine
 * @param {object} templateLogic - the Template Logic
 * @param {object} contractJson - contract data in JSON
 * @param {object} stateJson - state data in JSON
 * @param {string} currentTime - the definition of 'now'
 * @param {object} requestJson - state data in JSON
 * @returns {object} Promise to the response
 */
function execute(engine,templateLogic,contractJson,stateJson,currentTime,requestJson) {
    templateLogic.compileLogic();
    return engine.execute(templateLogic,templateLogic.getContractName(),contractJson,requestJson,stateJson,currentTime);
}

// Defaults
const defaultState = {'stateId':'org.accordproject.cicero.contract.AccordContractState#1','$class':'org.accordproject.cicero.contract.AccordContractState'};

Before(function () {
    this.engine = new Engine();
    this.rootdir = Util.resolveRootDir(this.parameters);
    this.currentTime = '1970-01-01T00:00:00Z';
    this.templateLogic = new TemplateLogic('es6');
    this.state = defaultState;
});

Given('the target platform {string}', function (target) {
    this.templateLogic.setTarget(target);
});

Given('the current time is {string}', function(currentTime) {
    this.currentTime = currentTime;
});

Given('the Ergo contract {string} in file {string}', function(paramName,paramFile) {
    this.templateLogic.setContractName(paramName);
    const fileName = Path.resolve(this.rootdir, paramFile);
    const logicFile = Fs.readFileSync(fileName, 'utf8');
    this.templateLogic.addLogicFile(logicFile,paramFile);
});

Given('the Ergo logic in file {string}', function(paramFile) {
    const fileName = Path.resolve(this.rootdir, paramFile);
    const logicFile = Fs.readFileSync(fileName, 'utf8');
    this.templateLogic.addLogicFile(logicFile,paramFile);
});

Given('the model in file {string}', function(paramFile) {
    const fileName = Path.resolve(this.rootdir, paramFile);
    const modelFile = Fs.readFileSync(fileName, 'utf8');
    this.templateLogic.addModelFile(modelFile,paramFile);
});

Given('the contract data', function (actualContract) {
    this.contract = JSON.parse(actualContract);
});

Given('the state', function (actualState) {
    this.state = JSON.parse(actualState);
});

When('it is in the state', function (actualState) {
    this.state = JSON.parse(actualState);
});

When('it receives the request', function (actualRequest) {
    this.request = JSON.parse(actualRequest);
});

Then('it should respond with', function (expectedResponse) {
    const response = JSON.parse(expectedResponse);
    if (this.answer) {
        expect(this.answer).to.have.property('response');
        expect(this.answer).to.not.have.property('error');
        return compare(response,this.answer.response);
    } else {
        return execute(this.engine,this.templateLogic,this.contract,this.state,this.currentTime,this.request)
            .then((actualAnswer) => {
                this.answer = actualAnswer;
                expect(actualAnswer).to.have.property('response');
                expect(actualAnswer).to.not.have.property('error');
                return compare(response,actualAnswer.response);
            });
    }
});

Then('the initial state( of the contract) should be', function (expectedState) {
    const state = JSON.parse(expectedState);
    return init(this.engine,this.templateLogic,this.contract,this.currentTime)
        .then((actualAnswer) => {
            expect(actualAnswer).to.have.property('state');
            expect(actualAnswer).to.not.have.property('error');
            return compare(state,actualAnswer.state);
        });
});

Then('the initial state( of the contract) should be the default state', function () {
    const state = defaultState;
    return init(this.engine,this.templateLogic,this.contract,this.currentTime)
        .then((actualAnswer) => {
            expect(actualAnswer).to.have.property('state');
            expect(actualAnswer).to.not.have.property('error');
            return compare(state,actualAnswer.state);
        });
});

Then('the new state( of the contract) should be', function (expectedState) {
    const state = JSON.parse(expectedState);
    if (this.answer) {
        expect(this.answer).to.have.property('state');
        expect(this.answer).to.not.have.property('error');
        return compare(state,this.answer.state);
    } else {
        return execute(this.engine,this.templateLogic,this.contract,this.state,this.currentTime,this.request)
            .then((actualAnswer) => {
                this.answer = actualAnswer;
                expect(actualAnswer).to.have.property('state');
                expect(actualAnswer).to.not.have.property('error');
                return compare(state,actualAnswer.state);
            });
    }
});

Then('the following obligations have( also) been emitted', function (expectedEmit) {
    const emit = JSON.parse(expectedEmit);
    if (this.answer) {
        expect(this.answer).to.have.property('emit');
        expect(this.answer).to.not.have.property('error');
        return compare(emit,this.answer.emit);
    } else {
        return execute(this.engine,this.templateLogic,this.contract,this.state,this.currentTime,this.request)
            .then((actualAnswer) => {
                this.answer = actualAnswer;
                expect(actualAnswer).to.have.property('emit');
                expect(actualAnswer).to.not.have.property('error');
                return compare(emit,actualAnswer.emit);
            });
    }
});

Then('it should fail with the error', function (expectedError) {
    const error = JSON.parse(expectedError);
    return execute(this.engine,this.templateLogic,this.contract,this.state,this.currentTime,this.request)
        .then((actualAnswer) => {
            this.answer = actualAnswer;
            expect(actualAnswer).to.have.property('error');
            expect(actualAnswer).to.not.have.property('state');
            expect(actualAnswer).to.not.have.property('response');
            return compare(error,actualAnswer.error);
        });
});

Then('it should fail to initialize with the error', function (expectedError) {
    const error = JSON.parse(expectedError);
    return init(this.engine,this.templateLogic,this.contract,this.currentTime)
        .then((actualAnswer) => {
            expect(actualAnswer).to.have.property('error');
            expect(actualAnswer).to.not.have.property('state');
            expect(actualAnswer).to.not.have.property('response');
            return compare(error,actualAnswer.error);
        });
});
